//
//import Firebase
//import Combine
//import FirebaseFires
//
//class AuthManager: ObservableObject {
//    @Published var user: User?
//    private var cancellables = Set<AnyCancellable>()
//
//    init() {
//        Auth.auth().addStateDidChangeListener { [weak self] _, user in
//            self?.user = user
//        }
//    }
//
//    func signUp(email: String, password: String) -> AnyPublisher<User, Error> {
//        Deferred {
//            Future { promise in
//                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
//                    if let error = error {
//                        promise(.failure(error))
//                    } else if let user = authResult?.user {
//                        promise(.success(user))
//                    }
//                }
//            }
//        }.eraseToAnyPublisher()
//    }
//
//    func signIn(email: String, password: String) -> AnyPublisher<User, Error> {
//        Deferred {
//            Future { promise in
//                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
//                    if let error = error {
//                        promise(.failure(error))
//                    } else if let user = authResult?.user {
//                        promise(.success(user))
//                    }
//                }
//            }
//        }.eraseToAnyPublisher()
//    }
//
//    func signOut() {
//        do {
//            try Auth.auth().signOut()
//        } catch {
//            print("Error signing out: \(error.localizedDescription)")
//        }
//    }
//}
