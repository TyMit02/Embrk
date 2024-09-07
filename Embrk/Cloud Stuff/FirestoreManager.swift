import FirebaseFirestore

class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    
    func createUser(userId: String, username: String, email: String) {
        let userData: [String: Any] = [
            "username": username,
            "email": email,
            "createdAt": FieldValue.serverTimestamp(),
            "participatingChallenges": [],
            "completedChallenges": [],
            "createdChallenges": [],
            "friends": []
        ]
        
        db.collection("users").document(userId).setData(userData) { error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
            } else {
                print("User created successfully")
            }
        }
    }
    
    func createChallenge(title: String, description: String, creatorId: String, startDate: Date, endDate: Date, type: String, difficulty: String, maxParticipants: Int, verificationMethod: String) {
        let challengeData: [String: Any] = [
            "title": title,
            "description": description,
            "creatorId": creatorId,
            "startDate": startDate,
            "endDate": endDate,
            "type": type,
            "difficulty": difficulty,
            "participants": [creatorId],
            "maxParticipants": maxParticipants,
            "verificationMethod": verificationMethod,
            "isActive": true
        ]
        
        db.collection("challenges").addDocument(data: challengeData) { error in
            if let error = error {
                print("Error creating challenge: \(error.localizedDescription)")
            } else {
                print("Challenge created successfully")
            }
        }
    }
}