//
//  ChallengeManager.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/8/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import Combine

class ChallengeManager: ObservableObject {
    private let authManager: AuthManager
    private let firestoreService: FirestoreService
    
    @Published var challenges: [Challenge] = []
    @Published var currentUser: User?
    @Published var users: [User] = []
    @Published var isLoggedIn: Bool = false
    @Published var joinedChallengesCount: Int = 0
    @Published var activeChallenges: [Challenge] = []
    @Published var featuredChallenge: Challenge?
    @Published var officialChallenges: [Challenge] = []
    @Published var communityChallenges: [Challenge] = []
    private var cancellables: Set<AnyCancellable> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var completedChallengesCount: Int = 0
    @Published var createdChallengesCount: Int = 0
    @Published var recentActivities: [ActivityItem] = []
    @Published var joinedChallenges: [Challenge] = []
    @Published var completedChallenges: [Challenge] = []
    @Published var createdChallenges: [Challenge] = []
    
    private let db = Firestore.firestore()
    private let leaderboardManager = LeaderboardManager()
    
    init(authManager: AuthManager, firestoreService: FirestoreService) {
        self.authManager = authManager
        self.firestoreService = firestoreService
        setupSubscriptions()
        setupChallengeListener()
        fetchUsers()
    }
    
    private func setupSubscriptions() {
        authManager.$currentUser
            .sink { [weak self] user in
                self?.currentUser = user
                print("DEBUG: Current user updated: \(user?.id ?? "nil")")
            }
            .store(in: &cancellables)
    }
    
    func checkAndHandleCompletedChallenges() {
        let now = Date()
        for challenge in challenges {
            let endDate = challenge.startDate.addingTimeInterval(TimeInterval(challenge.durationInDays * 24 * 60 * 60))
            if now > endDate {
                if challenge.isOfficial {
                    resetOfficialChallenge(challenge)
                } else {
                    handleCompletedCommunityChallenge(challenge)
                }
            }
        }
    }
    
    private func resetOfficialChallenge(_ challenge: Challenge) {
        var updatedChallenge = challenge
        updatedChallenge.startDate = Date()
        updatedChallenge.participatingUsers = []
        updatedChallenge.userProgress = [:]
        updateChallenge(updatedChallenge)
    }
    
    private func handleCompletedCommunityChallenge(_ challenge: Challenge) {
        for userId in challenge.participatingUsers {
            if let progress = challenge.userProgress[userId], progress.count >= challenge.durationInDays {
                addCompletedChallenge(challenge, for: userId)
            }
        }
        deleteChallenge(challenge)
    }
    
    private func addCompletedChallenge(_ challenge: Challenge, for userId: String) {
        db.collection("users").document(userId).updateData([
            "completedChallenges": FieldValue.arrayUnion([challenge.id])
        ]) { error in
            if let error = error {
                print("Error adding completed challenge: \(error)")
            }
        }
    }
    
    func updateActiveChallenges() {
        guard let currentUserId = authManager.currentUser?.id else { return }
        activeChallenges = challenges.filter { $0.participatingUsers.contains(currentUserId) }
    }
    
    func updateFeaturedChallenge() {
        featuredChallenge = challenges.filter { $0.isOfficial }.randomElement()
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
    
    func getOfficialChallenges() -> [Challenge] {
        return challenges.filter { $0.isOfficial }
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
    
    @MainActor
    func joinChallenge(_ challengeId: String) async throws {
        print("DEBUG: Attempting to join challenge: \(challengeId)")
        guard let userId = currentUser?.id,
              var challenge = challenges.first(where: { $0.id == challengeId }) else {
            throw NSError(domain: "ChallengeManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Challenge or user not found"])
        }
        
        if !challenge.participatingUsers.contains(userId) {
            challenge.participatingUsers.append(userId)
            try await firestoreService.updateChallenge(challenge)
            if let index = challenges.firstIndex(where: { $0.id == challengeId }) {
                challenges[index] = challenge
            }
            print("DEBUG: Successfully joined challenge: \(challengeId)")
        } else {
            print("DEBUG: User is already participating in this challenge")
        }
    }
    
    @MainActor
    func leaveChallenge(_ challengeId: String) async throws {
        print("DEBUG: Attempting to leave challenge: \(challengeId)")
        guard let userId = currentUser?.id,
              var challenge = challenges.first(where: { $0.id == challengeId }) else {
            throw NSError(domain: "ChallengeManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Challenge or user not found"])
        }
        
        if challenge.participatingUsers.contains(userId) {
            challenge.participatingUsers.removeAll { $0 == userId }
            try await firestoreService.updateChallenge(challenge)
            if let index = challenges.firstIndex(where: { $0.id == challengeId }) {
                challenges[index] = challenge
            }
            print("DEBUG: Successfully left challenge: \(challengeId)")
        } else {
            print("DEBUG: User is not participating in this challenge")
        }
    }
    
    func getChallenge(by id: String) -> Challenge? {
        let challenge = challenges.first { $0.id == id }
        print("DEBUG: getChallenge for id \(id). Found: \(challenge != nil)")
        return challenge
    }
    
    func isParticipating(in challenge: Challenge) -> Bool {
        let result = challenge.participatingUsers.contains(currentUser?.id ?? "")
        print("DEBUG: isParticipating check for challenge \(challenge.id ?? "unknown"): \(result)")
        return result
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
    
    func markDayAsCompleted(for challengeId: String) {
        guard let currentUser = currentUser,
              let challengeIndex = challenges.firstIndex(where: { $0.id == challengeId }) else {
            return
        }
        
        var challenge = challenges[challengeIndex]
        var progress = challenge.userProgress[currentUser.id ?? ""] ?? []
        
        let today = Calendar.current.startOfDay(for: Date())
        if !progress.contains(where: { Calendar.current.isDate($0.dateValue(), inSameDayAs: today) }) {
            progress.append(Timestamp(date: today))
            challenge.userProgress[currentUser.id ?? ""] = progress
            updateChallenge(challenge)
            
            // Calculate current streak
            let currentStreak = calculateCurrentStreak(progress: progress)
            
            // Update the leaderboard
            leaderboardManager.updateScore(
                forChallenge: challengeId,
                userId: currentUser.id ?? "",
                daysCompleted: progress.count,
                currentStreak: currentStreak,
                challengeDifficulty: challenge.difficulty
            )
        }
    }
    
    private func calculateCurrentStreak(progress: [Timestamp]) -> Int {
        let sortedDates = progress.map { $0.dateValue() }.sorted(by: >)
        var streak = 0
        var lastDate: Date?
        
        for date in sortedDates {
            if let last = lastDate {
                let daysBetween = Calendar.current.dateComponents([.day], from: date, to: last).day ?? 0
                if daysBetween == 1 {
                    streak += 1
                } else {
                    break
                }
            } else {
                streak = 1
            }
            lastDate = date
        }
        
        return streak
    }
    
    func fetchChallenges() {
        db.collection("challenges").addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching challenges: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self?.challenges = documents.compactMap { document -> Challenge? in
                try? document.data(as: Challenge.self)
            }
        }
    }
    
    func updateProgress(for challengeId: String, userId: String, progress: [Timestamp]) {
        let challengeRef = db.collection("challenges").document(challengeId)
        challengeRef.updateData([
            "userProgress.\(userId)": progress
        ]) { error in
            if let error = error {
                print("Error updating progress: \(error)")
            } else {
                print("Progress updated successfully")
            }
        }
    }
    
    func getUserProgress(for challengeId: String, userId: String) -> Int {
        guard let challenge = challenges.first(where: { $0.id == challengeId }) else {
            return 0
        }
        return challenge.userProgress[userId]?.count ?? 0
    }
    
    func getUser(by id: String) -> User? {
        return users.first { $0.id == id }
    }
    
    func updateProgress(for challengeId: String, userId: String, newProgress: Int) {
        let challengeRef = db.collection("challenges").document(challengeId)
        let leaderboardRef = db.collection("leaderboards").document(challengeId).collection("entries").document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let challengeDocument: DocumentSnapshot
            do {
                try challengeDocument = transaction.getDocument(challengeRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var challenge = try? challengeDocument.data(as: Challenge.self) else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Challenge not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Update challenge progress
            if var userProgress = challenge.userProgress[userId] {
                userProgress.append(Timestamp(date: Date()))
                challenge.userProgress[userId] = userProgress
            } else {
                challenge.userProgress[userId] = [Timestamp(date: Date())]
            }
            
            // Calculate current streak
            let currentStreak = self.calculateCurrentStreak(progress: challenge.userProgress[userId] ?? [])
            
            // Update challenge document
            do {
                try transaction.setData(from: challenge, forDocument: challengeRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            // Update leaderboard
            let leaderboardEntry = LeaderboardEntry(
                userId: userId,
                username: "", // We'll need to fetch this separately
                score: 0, // This will be calculated in LeaderboardManager
                daysCompleted: newProgress,
                currentStreak: currentStreak,
                longestStreak: currentStreak, // This should be max of current and previous longest
                lastUpdated: Date()
            )
            
            do {
                try transaction.setData(from: leaderboardEntry, forDocument: leaderboardRef, merge: true)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
            } else {
                print("Transaction successfully committed!")
                self.leaderboardManager.updateScore(
                    forChallenge: challengeId,
                    userId: userId,
                    daysCompleted: newProgress,
                    currentStreak: self.calculateCurrentStreak(progress: self.challenges.first(where: { $0.id == challengeId })?.userProgress[userId] ?? []),
                    challengeDifficulty: self.challenges.first(where: { $0.id == challengeId })?.difficulty ?? "Medium"
                )
            }
        }
    }
    
    func loadUsers() {
        firestoreService.fetchUsers { [weak self] result in
            switch result {
            case .success(let users):
                DispatchQueue.main.async {
                    self?.users = users
                }
            case .failure(let error):
                print("Error loading users: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadCurrentUser() {
        authManager.$currentUser
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.currentUser = user
                print("DEBUG: Current user loaded: \(user.id ?? "unknown")")
            }
            .store(in: &cancellables)
    }
    
    func validateChallengeForToday(_ challengeId: String) {
           guard let userId = authManager.currentUser?.id else { return }
           
           firestoreService.validateChallengeForToday(challengeId: challengeId, userId: userId) { [weak self] result in
               switch result {
               case .success:
                   print("Challenge validated successfully")
                   self?.updateLocalChallengeProgress(challengeId: challengeId, userId: userId)
               case .failure(let error):
                   print("Error validating challenge: \(error.localizedDescription)")
               }
           }
       }
    
    private func updateLocalChallengeProgress(challengeId: String, userId: String) {
           if var challenge = challenges.first(where: { $0.id == challengeId }) {
               let today = Timestamp(date: Date())
               challenge.userProgress[userId, default: []].append(today)
               
               if let index = challenges.firstIndex(where: { $0.id == challengeId }) {
                   challenges[index] = challenge
               }
               
               objectWillChange.send()
           }
       }
    
    func resetAllChallengeData(completion: @escaping (Result<Void, Error>) -> Void) {
            firestoreService.resetAllChallengeData { [weak self] result in
                switch result {
                case .success:
                    self?.loadChallenges()
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }

        func resetUserParticipations(completion: @escaping (Result<Void, Error>) -> Void) {
            firestoreService.resetUserParticipations { [weak self] result in
                switch result {
                case .success:
                    self?.loadChallenges()
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    
    @MainActor
       func refreshChallenge(_ challengeId: String) async throws -> Challenge {
           print("DEBUG: Refreshing challenge: \(challengeId)")
           let updatedChallenge = try await firestoreService.fetchChallenge(challengeId)
           if let index = challenges.firstIndex(where: { $0.id == challengeId }) {
               challenges[index] = updatedChallenge
           }
           print("DEBUG: Refreshed challenge. Participant count: \(updatedChallenge.participatingUsers.count)")
           return updatedChallenge
       }
    
    private func setupChallengeListener() {
          firestoreService.challengesPublisher
              .receive(on: DispatchQueue.main)
              .sink { [weak self] challenges in
                  self?.challenges = challenges
                  print("DEBUG: Received \(challenges.count) challenges from Firestore")
              }
              .store(in: &cancellables)
      }
    
    func loadChallenges() {
           isLoading = true
           errorMessage = nil
           
           firestoreService.fetchChallenges { [weak self] result in
               DispatchQueue.main.async {
                   self?.isLoading = false
                   switch result {
                   case .success(let challenges):
                       self?.challenges = challenges
                   case .failure(let error):
                       self?.errorMessage = error.localizedDescription
                   }
               }
           }
       }
    
    func loadUserChallenges(for userId: String) {
            loadJoinedChallenges(for: userId)
            loadCompletedChallenges(for: userId)
            loadCreatedChallenges(for: userId)
        }

        private func loadJoinedChallenges(for userId: String) {
            db.collection("challenges")
                .whereField("participatingUsers", arrayContains: userId)
                .getDocuments { [weak self] (querySnapshot, error) in
                    if let error = error {
                        print("Error getting joined challenges: \(error)")
                        return
                    }
                    
                    self?.joinedChallenges = querySnapshot?.documents.compactMap { document -> Challenge? in
                        try? document.data(as: Challenge.self)
                    } ?? []
                }
        }

        private func loadCompletedChallenges(for userId: String) {
            db.collection("challenges")
                .whereField("participatingUsers", arrayContains: userId)
                .getDocuments { [weak self] (querySnapshot, error) in
                    if let error = error {
                        print("Error getting completed challenges: \(error)")
                        return
                    }
                    
                    self?.completedChallenges = querySnapshot?.documents.compactMap { document -> Challenge? in
                        guard let challenge = try? document.data(as: Challenge.self) else { return nil }
                        let userProgress = challenge.userProgress[userId]?.count ?? 0
                        return userProgress >= challenge.durationInDays ? challenge : nil
                    } ?? []
                }
        }

        private func loadCreatedChallenges(for userId: String) {
            db.collection("challenges")
                .whereField("creatorId", isEqualTo: userId)
                .getDocuments { [weak self] (querySnapshot, error) in
                    if let error = error {
                        print("Error getting created challenges: \(error)")
                        return
                    }
                    
                    self?.createdChallenges = querySnapshot?.documents.compactMap { document -> Challenge? in
                        try? document.data(as: Challenge.self)
                    } ?? []
                }
        }
    
    
    func checkInForChallenge(_ challengeId: String) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw NSError(domain: "ChallengeManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }

        let challengeRef = db.collection("challenges").document(challengeId)
        
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let challengeSnapshot: DocumentSnapshot
            do {
                try challengeSnapshot = transaction.getDocument(challengeRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard var challenge = try? challengeSnapshot.data(as: Challenge.self) else {
                let error = NSError(domain: "ChallengeManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Challenge not found"])
                errorPointer?.pointee = error
                return nil
            }

            let today = Timestamp(date: Date())
            if var userProgress = challenge.userProgress[userId] {
                if !userProgress.contains(where: { Calendar.current.isDate($0.dateValue(), inSameDayAs: today.dateValue()) }) {
                    userProgress.append(today)
                    challenge.userProgress[userId] = userProgress
                }
            } else {
                challenge.userProgress[userId] = [today]
            }

            do {
                try transaction.setData(from: challenge, forDocument: challengeRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            return nil
        }

        // After successful check-in, update local data
        await MainActor.run {
            if let index = self.joinedChallenges.firstIndex(where: { $0.id == challengeId }) {
                self.joinedChallenges[index].userProgress[userId, default: []].append(Timestamp(date: Date()))
            }
        }
    }
  
    func getChallengeProgress(for challengeId: String) -> Double? {
           guard let userId = authManager.currentUser?.id,
                 let challenge = joinedChallenges.first(where: { $0.id == challengeId }) else {
               return nil
           }

           let userProgress = challenge.userProgress[userId]?.count ?? 0
           return Double(userProgress) / Double(challenge.durationInDays)
       }

       func isChallengecompleted(_ challengeId: String) -> Bool {
           guard let progress = getChallengeProgress(for: challengeId) else {
               return false
           }
           return progress >= 1.0
       }
    func fetchUsers() {
          let db = Firestore.firestore()
          db.collection("users").getDocuments { [weak self] (querySnapshot, error) in
              guard let self = self else { return }
              
              if let error = error {
                  print("Error getting users: \(error.localizedDescription)")
                  return
              }
              
              guard let documents = querySnapshot?.documents else {
                  print("No users found")
                  return
              }
              
              self.users = documents.compactMap { document -> User? in
                  do {
                      var user = try document.data(as: User.self)
                      user.id = document.documentID
                      return user
                  } catch {
                      print("Error decoding user: \(error.localizedDescription)")
                      return nil
                  }
              }
              
              print("Fetched \(self.users.count) users")
          }
      }
   }
extension ChallengeManager {
    func updateChallengeProgress(for challengeId: String, userId: String, progress: Int) async throws {
        let db = Firestore.firestore()
        let progressRef = db.collection("challengeProgress")
            .document(challengeId)
            .collection("userProgress")
            .document(userId)

        try await progressRef.setData([
            "todayProgress": progress,
            "lastUpdated": Timestamp(date: Date())
        ], merge: true)

        print("Updated progress for challenge \(challengeId), user \(userId): \(progress)")
    }
   
    func addActivity(username: String, description: String, iconName: String) {
           let timestamp = Date()
           let newActivity = ActivityItem(username: username, description: description, timestamp: timestamp, iconName: iconName)
           
           // Add to local array
           recentActivities.insert(newActivity, at: 0)
           if recentActivities.count > 20 {
               recentActivities.removeLast()
           }
           
           // Add to Firestore
           db.collection("activities").addDocument(data: [
               "username": username,
               "description": description,
               "timestamp": timestamp,
               "iconName": iconName
           ]) { error in
               if let error = error {
                   print("Error adding activity: \(error.localizedDescription)")
               }
           }
       }
       
       func updateActivityTimes() {
           let now = Date()
           for (index, activity) in recentActivities.enumerated() {
               let timeAgo = calculateTimeAgo(from: activity.timestamp, to: now)
               recentActivities[index].timeAgo = timeAgo
           }
       }
       
       private func calculateTimeAgo(from date: Date, to now: Date) -> String {
           let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date, to: now)
           
           if let year = components.year, year > 0 {
               return year == 1 ? "1 year ago" : "\(year) years ago"
           } else if let month = components.month, month > 0 {
               return month == 1 ? "1 month ago" : "\(month) months ago"
           } else if let day = components.day, day > 0 {
               return day == 1 ? "1 day ago" : "\(day) days ago"
           } else if let hour = components.hour, hour > 0 {
               return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
           } else if let minute = components.minute, minute > 0 {
               return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
           } else {
               return "Just now"
           }
       }
       
       func fetchRecentActivities() {
           db.collection("activities")
               .order(by: "timestamp", descending: true)
               .limit(to: 20)
               .getDocuments { [weak self] (querySnapshot, error) in
                   guard let documents = querySnapshot?.documents else {
                       print("Error fetching activities: \(error?.localizedDescription ?? "Unknown error")")
                       return
                   }
                   
                   self?.recentActivities = documents.compactMap { document -> ActivityItem? in
                       let data = document.data()
                       guard let username = data["username"] as? String,
                             let description = data["description"] as? String,
                             let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                             let iconName = data["iconName"] as? String else {
                           return nil
                       }
                       return ActivityItem(username: username, description: description, timestamp: timestamp, iconName: iconName)
                   }
                   
                   self?.updateActivityTimes()
               }
       }
   }

   struct ActivityItem: Identifiable {
       let id = UUID()
       let username: String
       let description: String
       var timestamp: Date
       var timeAgo: String = ""
       let iconName: String
   }
