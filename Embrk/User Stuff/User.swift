//
//  User.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/8/24.
//


import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let username: String
    let email: String
    var isAdmin: Bool
    var friends: [String]
    var friendRequests: [FriendRequest]
    var createdChallenges: [String]
    var participatingChallenges: [String]
    var privacySettings: PrivacySettings
    var blockedUsers: [String]
    var points: Int

    init(username: String, email: String, isAdmin: Bool = false, friends: [String] = [], createdChallenges: [String] = [], participatingChallenges: [String] = [], privacySettings: PrivacySettings = PrivacySettings(), friendRequests: [FriendRequest] = [], blockedUsers: [String] = [], points: Int = 0) {
        self.username = username
        self.email = email
        self.isAdmin = isAdmin
        self.friends = friends
        self.friendRequests = friendRequests
        self.createdChallenges = createdChallenges
        self.participatingChallenges = participatingChallenges
        self.privacySettings = privacySettings
        self.blockedUsers = blockedUsers
        self.points = points
    }
}

struct FriendRequest: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let toUserId: String
    var status: FriendRequestStatus
    let timestamp: Date
}

enum FriendRequestStatus: String, Codable {
    case pending
    case accepted
    case declined
}

struct PrivacySettings: Codable {
    var showEmail: Bool = false
    var showCreatedChallenges: Bool = true
    var showParticipatingChallenges: Bool = true
}
