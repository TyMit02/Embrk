import Foundation
import FirebaseFirestore

struct FriendActivity: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let activityType: String
    let timestamp: Date
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case activityType
        case timestamp
        case description
    }
}

class ActivityManager: ObservableObject {
    @Published var activities: [FriendActivity] = []
    private let db = Firestore.firestore()
    
    init() {
        loadActivities()
    }
    
    func addActivity(userId: String, type: String, description: String) {
        let newActivity = FriendActivity(userId: userId, activityType: type, timestamp: Date(), description: description)
        do {
            let _ = try db.collection("activities").addDocument(from: newActivity)
            activities.append(newActivity)
            self.objectWillChange.send()
        } catch {
            print("Error adding activity: \(error)")
        }
    }
    
    func getActivitiesForFriends(_ friendIds: [String]) -> [FriendActivity] {
        return activities.filter { friendIds.contains($0.userId) }
    }
    
    private func loadActivities() {
        db.collection("activities").order(by: "timestamp", descending: true).limit(to: 100).addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            
            self.activities = documents.compactMap { queryDocumentSnapshot -> FriendActivity? in
                return try? queryDocumentSnapshot.data(as: FriendActivity.self)
            }
            
            self.objectWillChange.send()
        }
    }
}
