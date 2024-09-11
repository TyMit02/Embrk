import Firebase
import FirebaseFirestoreSwift

class FirestoreService {
    private let db = Firestore.firestore()
    
    func fetchChallenges(completion: @escaping (Result<[Challenge], Error>) -> Void) {
        db.collection("challenges").getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let challenges = querySnapshot?.documents.compactMap { document -> Challenge? in
                try? document.data(as: Challenge.self)
            } ?? []
            
            completion(.success(challenges))
        }
    }
    
    func updateChallenge(_ challenge: Challenge) {
        guard let id = challenge.id else { return }
        
        do {
            try db.collection("challenges").document(id).setData(from: challenge)
        } catch {
            print("Error updating challenge: \(error.localizedDescription)")
        }
    }
    
    func validateChallengeForToday(challengeId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let today = Timestamp(date: Date())
        
        db.collection("challenges").document(challengeId).updateData([
            "userProgress.\(userId)": FieldValue.arrayUnion([today])
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let users = querySnapshot?.documents.compactMap { document -> User? in
                try? document.data(as: User.self)
            } ?? []
            
            completion(.success(users))
        }
    }
    
    func fetchCurrentUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let document = document, document.exists {
                do {
                    var user = try document.data(as: User.self)
                    user.id = userId
                    completion(.success(user))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
            }
        }
    }
}