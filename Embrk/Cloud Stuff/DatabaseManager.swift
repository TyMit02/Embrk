import Firebase
import FirebaseFirestore

class DatabaseManager: ObservableObject {
    private let db = Firestore.firestore()

    func createUser(_ user: User) {
        do {
            try db.collection("users").document(user.id ?? "").setData(from: user)
        } catch {
            print("Error creating user: \(error.localizedDescription)")
        }
    }

    func getUser(id: String, completion: @escaping (User?) -> Void) {
        db.collection("users").document(id).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: User.self)
                    completion(user)
                } catch {
                    print("Error decoding user: \(error.localizedDescription)")
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    func updateUser(_ user: User) {
        do {
            try db.collection("users").document(user.id ?? "").setData(from: user)
        } catch {
            print("Error updating user: \(error.localizedDescription)")
        }
    }

    // Add more methods for challenges, friend requests, etc.
}
