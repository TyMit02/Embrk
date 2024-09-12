//
//  FriendsManager.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/11/24.
//


import Firebase
import FirebaseFirestore
import FirebaseAuth

class FriendsManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var friendRequests: [FriendRequest] = []
    @Published var friends: [User] = []
    
    private var listener: ListenerRegistration?
    
    func sendFriendRequest(to userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendsManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        let newRequest = FriendRequest(id: UUID().uuidString,
                                       fromUserId: currentUserId,
                                       toUserId: userId,
                                       status: .pending,
                                       timestamp: Date())
        
        try await db.collection("users").document(userId).updateData([
            "friendRequests": FieldValue.arrayUnion([try Firestore.Encoder().encode(newRequest)])
        ])
    }
    
    func acceptFriendRequest(_ request: FriendRequest) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendsManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }

        // Update the request status
        var updatedRequest = request
        updatedRequest.status = .accepted

        // Encode the friend request outside the transaction to avoid throwing inside the closure
        let encodedRequest: [String: Any]
        do {
            encodedRequest = try Firestore.Encoder().encode(request)
        } catch {
            throw NSError(domain: "FriendsManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }

        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let currentUserRef = self.db.collection("users").document(currentUserId)
            let otherUserRef = self.db.collection("users").document(request.fromUserId)
            
            // Update current user friends and friend requests
            transaction.updateData([
                "friends": FieldValue.arrayUnion([request.fromUserId]),
                "friendRequests": FieldValue.arrayRemove([encodedRequest])
            ], forDocument: currentUserRef)
            
            // Update other user friends list
            transaction.updateData([
                "friends": FieldValue.arrayUnion([currentUserId])
            ], forDocument: otherUserRef)
            
            return nil
        }
    }

    
    func declineFriendRequest(_ request: FriendRequest) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendsManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        try await db.collection("users").document(currentUserId).updateData([
            "friendRequests": FieldValue.arrayRemove([try Firestore.Encoder().encode(request)])
        ])
    }
    
    func removeFriend(_ friendId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendsManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let currentUserRef = self.db.collection("users").document(currentUserId)
            let friendUserRef = self.db.collection("users").document(friendId)
            
            transaction.updateData([
                "friends": FieldValue.arrayRemove([friendId])
            ], forDocument: currentUserRef)
            
            transaction.updateData([
                "friends": FieldValue.arrayRemove([currentUserId])
            ], forDocument: friendUserRef)
            
            return nil
        }
    }
    
    func blockUser(_ userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendsManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        try await db.collection("users").document(currentUserId).updateData([
            "blockedUsers": FieldValue.arrayUnion([userId]),
            "friends": FieldValue.arrayRemove([userId])
        ])
    }
    
    func unblockUser(_ userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FriendsManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        try await db.collection("users").document(currentUserId).updateData([
            "blockedUsers": FieldValue.arrayRemove([userId])
        ])
    }
    
    func startListening() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("users").document(currentUserId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let self = self else { return }
                
                do {
                    if let user = try? document.data(as: User?.self) {
                        self.friendRequests = user.friendRequests.filter { $0.status == .pending } ?? []
                        self.fetchFriends(friendIds: user.friends ?? [])
                    }
                } catch {
                    print("Error decoding user: \(error)")
                }
            }
    }
    
    private func fetchFriends(friendIds: [String]) {
        let dispatchGroup = DispatchGroup()
        
        var fetchedFriends: [User] = []
        
        for friendId in friendIds {
            dispatchGroup.enter()
            let docRef = db.collection("users").document(friendId)
            docRef.getDocument { (document, error) in
                defer { dispatchGroup.leave() }
                if let document = document, document.exists {
                    do {
                        if let friend = try document.data(as: User?.self) {
                            fetchedFriends.append(friend)
                        }
                    } catch {
                        print("Error decoding friend: \(error)")
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.friends = fetchedFriends
        }
    }
    
    func stopListening() {
        listener?.remove()
    }
}
