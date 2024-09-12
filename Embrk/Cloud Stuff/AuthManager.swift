import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    private let db = Firestore.firestore()
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        setupAuthStateListener()
    }

    private func setupAuthStateListener() {
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, firebaseUser) in
            if let firebaseUser = firebaseUser {
                self?.fetchUserData(userId: firebaseUser.uid) { result in
                    switch result {
                    case .success(let user):
                        self?.currentUser = user
                        self?.isLoggedIn = true
                    case .failure(let error):
                        print("Error fetching user data: \(error.localizedDescription)")
                        self?.isLoggedIn = false
                        self?.currentUser = nil
                    }
                }
            } else {
                self?.isLoggedIn = false
                self?.currentUser = nil
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userId = authResult?.user.uid else {
                completion(.failure(NSError(domain: "AuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])))
                return
            }
            
            self?.fetchUserData(userId: userId, completion: completion)
        }
    }

    func signUp(email: String, password: String, username: String, completion: @escaping (Result<User, Error>) -> Void) {
        print("Attempting to sign up with email: \(email)")
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error {
                print("Sign up error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let userId = authResult?.user.uid else {
                print("No user ID found after sign up")
                completion(.failure(NSError(domain: "AuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])))
                return
            }
            
            print("Successfully created account. User ID: \(userId)")
            self?.createUserDocument(userId: userId, email: email, username: username, completion: completion)
        }
    }

    private func fetchUserData(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
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
                completion(.failure(NSError(domain: "AuthManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User document not found"])))
            }
        }
    }

    private func createUserDocument(userId: String, email: String, username: String, completion: @escaping (Result<User, Error>) -> Void) {
        print("Creating new user document for User ID: \(userId)")
        let newUser = User(username: username, email: email)
        let userRef = db.collection("users").document(userId)

        do {
            try userRef.setData(from: newUser) { [weak self] error in
                if let error = error {
                    print("Error creating new user document: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    var createdUser = newUser
                    createdUser.id = userId
                    self?.currentUser = createdUser
                    self?.isLoggedIn = true
                    print("New user document created successfully: \(createdUser.username)")
                    completion(.success(createdUser))
                }
            }
        } catch {
            print("Error encoding user data: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.isLoggedIn = false
            completion(.success(()))
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    deinit {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
