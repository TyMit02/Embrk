import Foundation
import FirebaseFirestore


class ChallengeManager: ObservableObject {
    @Published var challenges: [Challenge] = []
    @Published var currentUser: User?
    @Published var users: [User] = []
    @Published var isLoggedIn: Bool = false
    @Published var joinedChallengesCount: Int = 0
    
    let activityManager = ActivityManager()
    private let pendingFriendRequestsKey = "PendingFriendRequests"
    private let userDefaultsKey = "UserCreatedChallenges"
    private let currentUserKey = "CurrentUser"
    private let usersKey = "Users"
    private let isLoggedInKey = "IsLoggedIn"
    private let friendsKey = "Friends"
    let notificationStore = NotificationStore()
    let notificationManager = NotificationManager.shared
    
    private var dailyCompletions: [((String, String), Set<Date>)] = []
    private let db = Firestore.firestore()
    
    init() {
        print("DEBUG: ChallengeManager initializing")
        loadUsers()
        loadCurrentUser()
        loadFriends()
        loadPendingFriendRequests()
        checkLoginState()
        loadChallenges()
        ensureOfficialChallenges()
        
        print("DEBUG: ChallengeManager initialization complete")
        print("DEBUG: Current user: \(currentUser?.username ?? "None")")
        print("DEBUG: Total users: \(users.count)")
        print("DEBUG: Current user friends: \(currentUser?.friends.count ?? 0)")
        print("DEBUG: Current user pending requests: \(currentUser?.pendingFriendRequests.count ?? 0)")
    }
    
    func loadChallenges() {
        db.collection("challenges").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting challenges: \(error)")
            } else {
                self.challenges = querySnapshot?.documents.compactMap { document -> Challenge? in
                    try? document.data(as: Challenge.self)
                } ?? []
                self.objectWillChange.send()
            }
        }
    }
    
    func addChallenge(_ challenge: Challenge) {
        do {
            let _ = try db.collection("challenges").addDocument(from: challenge)
            self.challenges.append(challenge)
            self.objectWillChange.send()
        } catch {
            print("Error adding challenge: \(error)")
        }
    }
    
    func updateChallenge(_ challenge: Challenge) {
        if let id = challenge.id {
            do {
                try db.collection("challenges").document(id).setData(from: challenge)
                if let index = self.challenges.firstIndex(where: { $0.id == challenge.id }) {
                    self.challenges[index] = challenge
                }
                self.objectWillChange.send()
            } catch {
                print("Error updating challenge: \(error)")
            }
        }
    }
    
    func deleteChallenge(_ challenge: Challenge) {
        if let id = challenge.id {
            db.collection("challenges").document(id).delete() { error in
                if let error = error {
                    print("Error removing challenge: \(error)")
                } else {
                    self.challenges.removeAll { $0.id == challenge.id }
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    func completeTaskForChallenge(_ challengeId: String, onDate date: Date = Date()) {
        guard let currentUser = currentUser,
              let challengeIndex = challenges.firstIndex(where: { $0.id == challengeId }) else {
            return
        }
        
        var challenge = challenges[challengeIndex]
        var progress = challenge.userProgress[currentUser.id ?? ""] ?? []
        progress.append(Timestamp(date: date))
        challenge.userProgress[currentUser.id ?? ""] = progress
        updateChallenge(challenge)
    }
    
    func markDayAsCompleted(for challengeId: String) {
        guard let currentUser = currentUser,
              let challengeIndex = challenges.firstIndex(where: { $0.id == challengeId }) else {
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        var challenge = challenges[challengeIndex]
        var progress = challenge.userProgress[currentUser.id ?? ""] ?? []
        
        if !progress.contains(where: { Calendar.current.isDate($0.dateValue(), inSameDayAs: today) }) {
            progress.append(Timestamp(date: today))
            challenge.userProgress[currentUser.id ?? ""] = progress
            updateChallenge(challenge)
            notificationStore.addNotification(title: "Daily Task Completed", message: "You've completed your daily task for \(challenge.title)")
            notificationManager.scheduleImmediateNotification(
                title: "Daily Task Completed",
                body: "Great job! You've completed your daily task for \(challenge.title)"
            )
        }
    }
    
    private func checkLoginState() {
        isLoggedIn = UserDefaults.standard.bool(forKey: isLoggedInKey)
        if isLoggedIn {
            loadCurrentUser()
        }
    }
    
    func acceptFriendRequest(from userId: String) throws {
        print("DEBUG: Accepting friend request from user ID: \(userId)")
        guard var currentUser = currentUser else {
            print("DEBUG: Current user is nil")
            throw FriendRequestError.currentUserNotFound
        }
        
        guard let index = currentUser.pendingFriendRequests.firstIndex(of: userId) else {
            print("DEBUG: User ID not found in pending requests")
            throw FriendRequestError.requestNotFound
        }
        
        currentUser.pendingFriendRequests.remove(at: index)
        currentUser.friends.append(userId)
        
        if var otherUser = users.first(where: { $0.id == userId }) {
            otherUser.friends.append(currentUser.id ?? "")
            otherUser.sentFriendRequests.removeAll { $0 == currentUser.id }
            
            if let otherUserIndex = users.firstIndex(where: { $0.id == userId }) {
                users[otherUserIndex] = otherUser
            }
            
            print("DEBUG: Updated both users' friend lists")
        } else {
            print("DEBUG: Couldn't find other user in users array")
            throw FriendRequestError.userNotFound
        }
        
        self.currentUser = currentUser
        if let currentUserIndex = users.firstIndex(where: { $0.id == currentUser.id }) {
            users[currentUserIndex] = currentUser
        }
        
        objectWillChange.send()
        saveUsers()
        saveFriends()
        savePendingFriendRequests()
        print("DEBUG: Friend request accepted and all data saved")
    }
    
    func rejectFriendRequest(from userId: String) throws {
        print("DEBUG: Rejecting friend request from user ID: \(userId)")
        guard var currentUser = currentUser else {
            print("DEBUG: Current user is nil")
            throw FriendRequestError.currentUserNotFound
        }
        
        guard let index = currentUser.pendingFriendRequests.firstIndex(of: userId) else {
            print("DEBUG: User ID not found in pending requests")
            throw FriendRequestError.requestNotFound
        }
        
        currentUser.pendingFriendRequests.remove(at: index)
        
        if let userIndex = users.firstIndex(where: { $0.id == userId }) {
            users[userIndex].sentFriendRequests.removeAll { $0 == currentUser.id }
        }
        
        self.currentUser = currentUser
        if let currentUserIndex = users.firstIndex(where: { $0.id == currentUser.id }) {
            users[currentUserIndex] = currentUser
        }
        
        objectWillChange.send()
        saveUsers()
        savePendingFriendRequests()
        print("DEBUG: Friend request rejected and all data saved")
    }
    
    func getUserProgressForChallenge(_ challengeId: String) -> Int? {
        guard let currentUser = currentUser,
              let challenge = challenges.first(where: { $0.id == challengeId }) else {
            return nil
        }
        
        return challenge.userProgress[currentUser.id ?? ""]?.count ?? 0
    }
    
    func canMarkTodayAsCompleted(for challengeId: String) -> Bool {
        guard let currentUser = currentUser,
              let challenge = challenges.first(where: { $0.id == challengeId }) else {
            return false
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let progress = challenge.userProgress[currentUser.id ?? ""] ?? []
        return !progress.contains(where: { Calendar.current.isDate($0.dateValue(), inSameDayAs: today) })
    }
    
    private func ensureOfficialChallenges() {
        let officialChallenges = OfficialChallengeData.officialChallenges
        for officialChallenge in officialChallenges {
            if !challenges.contains(where: { $0.id == officialChallenge.id }) {
                addChallenge(officialChallenge)
            }
        }
    }
    
    func joinChallenge(_ challengeId: String) -> Bool {
        guard let currentUser = currentUser,
              let index = challenges.firstIndex(where: { $0.id == challengeId }) else {
            return false
        }
        
        var challenge = challenges[index]
        
        if !ProManager.shared.isPro && !isDebugUser() && joinedChallengesCount >= 3 {
            return false
        }
        
        if challenge.currentParticipants < challenge.maxParticipants &&
            !challenge.participatingUsers.contains(currentUser.id ?? "") {
            challenge.participatingUsers.append(currentUser.id ?? "")
            joinedChallengesCount += 1
            updateChallenge(challenge)
            
            notificationManager.scheduleReminderForChallenge(challenge)
            notificationManager.scheduleImmediateNotification(
                title: "Challenge Joined",
                body: "You've successfully joined the challenge: \(challenge.title)"
            )
            return true
        }
        
        return false
    }
    
    func leaveChallenge(_ challengeId: String) -> Bool {
        guard let currentUser = currentUser,
              let index = challenges.firstIndex(where: { $0.id == challengeId }) else {
            return false
        }
        
        var challenge = challenges[index]
        
        if let userIndex = challenge.participatingUsers.firstIndex(of: currentUser.id ?? "") {
            challenge.participatingUsers.remove(at: userIndex)
            joinedChallengesCount -= 1
            updateChallenge(challenge)
            notificationManager.cancelReminderForChallenge(challenge)
            notificationManager.scheduleImmediateNotification(
                title: "Challenge Left",
                body: "You've left the challenge: \(challenge.title)"
            )
            return true
        }
        
        return false
    }
    
    func isParticipating(in challenge: Challenge) -> Bool {
        guard let currentUser = currentUser else { return false }
        return challenge.participatingUsers.contains(currentUser.id ?? "")
    }
    
    func login(user: User) {
        setCurrentUser(user)
        loadChallenges()
        ensureOfficialChallenges()
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: isLoggedInKey)
        objectWillChange.send()
    }
    
    func logOut() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: isLoggedInKey)
        UserDefaults.standard.removeObject(forKey: currentUserKey)
        UserDefaults.standard.removeObject(forKey: friendsKey)
        UserDefaults.standard.removeObject(forKey: pendingFriendRequestsKey)
        objectWillChange.send()
    }
    
    func createUser(_ user: User) -> Bool {
        if users.contains(where: { $0.username == user.username || $0.email == user.email }) {
            return false
        }
        users.append(user)
        saveUsers()
        return true
    }
    
    func authenticateUser(email: String, password: String) -> User? {
        return users.first { $0.email == email && $0.hashedPassword == hashPassword(password) }
    }
    
    func setCurrentUser(_ user: User) {
        currentUser = user
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
        }
        saveFriends()
        savePendingFriendRequests()
    }
    
    private func loadCurrentUser() {
        if let data = UserDefaults.standard.data(forKey: currentUserKey),
           let decoded = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = decoded
            print("DEBUG: Loaded current user: \(decoded.username)")
        }
    }
    
    func getChallengesForUser(_ user: User) -> (created: [Challenge], participating: [Challenge]) {
        let createdChallenges = challenges.filter { user.createdChallenges.contains($0.id ?? "") }
        let participatingChallenges = challenges.filter { user.participatingChallenges.contains($0.id ?? "") }
        return (createdChallenges, participatingChallenges)
    }
    
    func addCreatedChallenge(_ challenge: Challenge, for user: User) {
        if var updatedUser = users.first(where: { $0.id == user.id }) {
            updatedUser.createdChallenges.append(challenge.id ?? "")
            updateUser(updatedUser)
        }
    }
    
    func addParticipatingChallenge(_ challenge: Challenge, for user: User) {
        if var updatedUser = users.first(where: { $0.id == user.id }) {
            updatedUser.participatingChallenges.append(challenge.id ?? "")
            updateUser(updatedUser)
        }
    }
    
    func sendFriendRequest(to userId: String) {
        guard let currentUser = currentUser else { return }
        if let index = users.firstIndex(where: { $0.id == userId }) {
            users[index].pendingFriendRequests.append(currentUser.id ?? "")
            if var updatedCurrentUser = users.first(where: { $0.id == currentUser.id }) {
                updatedCurrentUser.sentFriendRequests.append(userId)
                if let currentUserIndex = users.firstIndex(where: { $0.id == currentUser.id }) {
                    users[currentUserIndex] = updatedCurrentUser
                }
                self.currentUser = updatedCurrentUser
            }
            objectWillChange.send()
            saveUsers()
            savePendingFriendRequests()
            print("DEBUG: Friend request sent and saved")
            
            // Send notification
            NotificationManager.shared.sendFriendRequestNotification(from: currentUser)
        }
    }
    
    private func savePendingFriendRequests() {
        guard let currentUser = currentUser else { return }
        let pendingRequestsData = currentUser.pendingFriendRequests
        UserDefaults.standard.set(pendingRequestsData, forKey: pendingFriendRequestsKey)
        print("DEBUG: Saved \(pendingRequestsData.count) pending friend requests")
    }
    
    private func loadPendingFriendRequests() {
        print("DEBUG: Loading pending friend requests")
        guard var currentUser = currentUser else {
            print("DEBUG: loadPendingFriendRequests - Current user is nil")
            return
        }
        if let pendingRequestsData = UserDefaults.standard.array(forKey: pendingFriendRequestsKey) as? [String] {
            let oldCount = currentUser.pendingFriendRequests.count
            currentUser.pendingFriendRequests = pendingRequestsData
            print("DEBUG: Loaded \(currentUser.pendingFriendRequests.count) pending friend requests")
            print("DEBUG: Old count: \(oldCount), New count: \(currentUser.pendingFriendRequests.count)")
            self.currentUser = currentUser
            if let index = users.firstIndex(where: { $0.id == currentUser.id }) {
                users[index] = currentUser
                print("DEBUG: Updated user in users array with loaded pending requests")
            }
        } else {
            print("DEBUG: No pending requests data found in UserDefaults")
        }
    }
    
    func removeFriend(_ friendId: String) {
        guard var currentUser = currentUser else { return }
        
        // Remove friend from current user's friends list
        currentUser.friends.removeAll { $0 == friendId }
        
        // Update current user in users array
        if let currentUserIndex = users.firstIndex(where: { $0.id == currentUser.id }) {
            users[currentUserIndex] = currentUser
        }
        
        // Remove current user from friend's friends list
        if let friendIndex = users.firstIndex(where: { $0.id == friendId }) {
            users[friendIndex].friends.removeAll { $0 == currentUser.id }
        }
        
        self.currentUser = currentUser
        objectWillChange.send()
        saveUsers()
        saveFriends()
        
        print("DEBUG: ChallengeManager - Friend removed and data saved")
    }
    
    private func saveFriends() {
        guard let currentUser = currentUser else { return }
        let friendsData = currentUser.friends
        UserDefaults.standard.set(friendsData, forKey: friendsKey)
        print("DEBUG: Saved \(friendsData.count) friends for current user")
    }
    
    private func loadFriends() {
        guard var currentUser = currentUser else {
            print("DEBUG: loadFriends - Current user is nil")
            return
        }
        if let friendsData = UserDefaults.standard.array(forKey: friendsKey) as? [String] {
            currentUser.friends = friendsData
            print("DEBUG: Loaded \(currentUser.friends.count) friends for current user")
            self.currentUser = currentUser
            if let index = users.firstIndex(where: { $0.id == currentUser.id }) {
                users[index] = currentUser
                print("DEBUG: Updated user in users array with loaded friends")
            }
        }
    }
    
    func getPendingFriendRequests() -> [User] {
        guard let currentUser = currentUser else {
            print("DEBUG: getPendingFriendRequests - Current user is nil")
            return []
        }
        let pendingRequests = users.filter { currentUser.pendingFriendRequests.contains($0.id ?? "") }
        print("DEBUG: Found \(pendingRequests.count) pending friend requests")
        return pendingRequests
    }
    
    func getFriends() -> [User] {
        guard let currentUser = currentUser else { return [] }
        return users.filter { currentUser.friends.contains($0.id ?? "") }
    }
    
    private func updateUser(_ user: User) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            saveUsers()
        }
    }
    
    private func saveUsers() {
        do {
            let encodedData = try JSONEncoder().encode(users)
            UserDefaults.standard.set(encodedData, forKey: usersKey)
            print("DEBUG: Saved \(users.count) users")
        } catch {
            print("Error saving users: \(error)")
        }
    }
    
    func loadUsers() {
        if let savedUsers = UserDefaults.standard.data(forKey: usersKey) {
            do {
                users = try JSONDecoder().decode([User].self, from: savedUsers)
                print("DEBUG: Loaded \(users.count) users")
                
                // Update current user with the latest data
                if let currentUser = currentUser,
                   let updatedUser = users.first(where: { $0.id == currentUser.id }) {
                    self.currentUser = updatedUser
                    print("DEBUG: Updated current user with latest data")
                }
            } catch {
                print("Error loading users: \(error)")
            }
        } else {
            print("DEBUG: No saved users data found")
        }
    }
    
    func isDebugUser() -> Bool {
        guard let currentUser = currentUser else {
            return false
        }
        
        return currentUser.email == "tymitchell100@gmail.com" &&
        currentUser.username == "TyMit02"
    }
    
    func resetAllUserData() {
        // Clear all user-related data from UserDefaults
        UserDefaults.standard.removeObject(forKey: usersKey)
        UserDefaults.standard.removeObject(forKey: currentUserKey)
        UserDefaults.standard.removeObject(forKey: friendsKey)
        UserDefaults.standard.removeObject(forKey: pendingFriendRequestsKey)
        UserDefaults.standard.removeObject(forKey: isLoggedInKey)
        
        // Reset in-memory data
        users = []
        currentUser = nil
        isLoggedIn = false
        
        // Reset challenges
        challenges.forEach { challenge in
            var updatedChallenge = challenge
            updatedChallenge.participatingUsers.removeAll()
            updatedChallenge.userProgress.removeAll()
            updateChallenge(updatedChallenge)
        }
        
        // Keep only official challenges
        challenges = challenges.filter { $0.isOfficial }
        
        // Trigger UI update
        objectWillChange.send()
        
        print("All user data and challenge participants have been reset.")
    }
    
    func blockUser(userId: String) {
        guard var currentUser = currentUser else { return }
        currentUser.blockedUsers.append(userId)
        removeFriend(userId) // Use your existing removeFriend method
        
        if let currentUserIndex = users.firstIndex(where: { $0.id == currentUser.id }) {
            users[currentUserIndex] = currentUser
        }
        
        self.currentUser = currentUser
        
        objectWillChange.send()
        saveUsers()
        print("DEBUG: User blocked and data saved")
    }
    
    func isUserBlocked(_ userId: String) -> Bool {
        return currentUser?.blockedUsers.contains(userId) ?? false
    }
    
    func logActivity(for userId: String, type: String, description: String) {
        activityManager.addActivity(userId: userId, type: type, description: description)
    }
    
    func getFriendActivities() -> [FriendActivity] {
        guard let currentUser = currentUser else { return [] }
        return activityManager.getActivitiesForFriends(currentUser.friends)
    }
    
    func getUser(by id: String) -> User? {
        return users.first { $0.id == id }
    }
    
    func getUserChallenges() -> [Challenge] {
        guard let currentUser = currentUser else { return [] }
        return challenges.filter { $0.participatingUsers.contains(currentUser.id ?? "") }
    }
    
    func getCompletedChallenges() -> [Challenge] {
        guard let currentUser = currentUser else { return [] }
        return challenges.filter { challenge in
            challenge.participatingUsers.contains(currentUser.id ?? "") && isChallengeCompleted(challenge)
        }
    }
    
    func getCompletedChallengesCount(for user: User) -> Int {
        return getCompletedChallenges().filter { $0.participatingUsers.contains(user.id ?? "") }.count
    }
    
    func getRecentActivity(for user: User) -> [String] {
        // This is a placeholder. Implement your actual logic here.
        return [
            "Joined challenge 'Summer Fitness'",
            "Completed day 5 of '30 Days of Coding'",
            "Created new challenge 'Book Reading Marathon'"
        ]
    }
    
    private func isChallengeCompleted(_ challenge: Challenge) -> Bool {
        guard let currentUser = currentUser else { return false }
        let key = (currentUser.id, challenge.id)
        guard let completedDates = dailyCompletions.first(where: { $0.0 == key })?.1 else {
            return false
        }
        
        let calendar = Calendar.current
        let startDate = challenge.startDate
        let endDate = calendar.date(byAdding: .day, value: challenge.durationInDays - 1, to: startDate)!
        
        var currentDate = startDate
        while currentDate <= endDate {
            if !completedDates.contains(currentDate) {
                return false
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return true
    }
    
    func getCurrentStreak() -> Int {
        guard let currentUser = currentUser else { return 0 }
        
        let calendar = Calendar.current
        var currentDate = Date()
        var streak = 0
        
        while true {
            let completedAnyChallenge = challenges.contains { challenge in
                let key = (currentUser.id, challenge.id)
                return dailyCompletions.first(where: { $0.0 == key })?.1.contains(currentDate) ?? false
            }
            
            if completedAnyChallenge {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    func markChallengeCompleted(challengeID: String, date: Date = Date()) {
        guard let currentUser = currentUser, let userId = currentUser.id else { return }
        let key = (userId, challengeID)
        if var completedDates = dailyCompletions.first(where: { $0.0 == key })?.1 {
            completedDates.insert(date)
            dailyCompletions[dailyCompletions.firstIndex(where: { $0.0 == key })!].1 = completedDates
        } else {
            dailyCompletions.append((key, [date]))
        }
    }
    
    enum FriendRequestError: Error {
        case currentUserNotFound
        case requestNotFound
        case userNotFound
    }
}
