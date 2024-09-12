//
//  FirestoreService.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//

import Combine
import Firebase
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private let challengesSubject = CurrentValueSubject<[Challenge], Never>([])
    
    var challengesPublisher: AnyPublisher<[Challenge], Never> {
        challengesSubject.eraseToAnyPublisher()
    }
    
    init() {
        setupChallengesListener()
    }
    
    // MARK: - Challenge Operations
    
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
    
    func updateChallenge(_ challenge: Challenge) async throws {
        guard let id = challenge.id else {
            throw NSError(domain: "FirestoreService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Challenge has no ID"])
        }
        
        try await db.collection("challenges").document(id).setData(from: challenge)
    }
    
    func fetchChallenge(_ challengeId: String) async throws -> Challenge {
        let documentSnapshot = try await db.collection("challenges").document(challengeId).getDocument()
        
        guard let challenge = try? documentSnapshot.data(as: Challenge.self) else {
            throw NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Challenge not found"])
        }
        
        return challenge
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
    
 
    // MARK: - User Operations
    
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
    
    // MARK: - Reset Operations
    
    func resetAllChallengeData(completion: @escaping (Result<Void, Error>) -> Void) {
        let batch = db.batch()
        
        db.collection("challenges").getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            snapshot?.documents.forEach { document in
                batch.updateData(["participatingUsers": [], "userProgress": [:]], forDocument: document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func resetUserParticipations(completion: @escaping (Result<Void, Error>) -> Void) {
        let batch = db.batch()
        
        db.collection("challenges").getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            snapshot?.documents.forEach { document in
                batch.updateData(["participatingUsers": []], forDocument: document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupChallengesListener() {
           db.collection("challenges").addSnapshotListener { [weak self] querySnapshot, error in
               guard let documents = querySnapshot?.documents else {
                   print("Error fetching challenges: \(error?.localizedDescription ?? "Unknown error")")
                   return
               }
               
               let challenges = documents.compactMap { document -> Challenge? in
                   try? document.data(as: Challenge.self)
               }
               
               DispatchQueue.main.async {
                   self?.challengesSubject.send(challenges)
               }
           }
       }
}
