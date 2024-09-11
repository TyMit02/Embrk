import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let username: String
    let email: String
    var friends: [String]
    var pendingFriendRequests: [String]
    var sentFriendRequests: [String]
    var createdChallenges: [String]
    var participatingChallenges: [String]
    var privacySettings: PrivacySettings
    var blockedUsers: [String]
    var points: Int

    init(username: String, email: String, friends: [String] = [], createdChallenges: [String] = [], participatingChallenges: [String] = [], privacySettings: PrivacySettings = PrivacySettings(), pendingFriendRequests: [String] = [], sentFriendRequests: [String] = [], blockedUsers: [String] = [], points: Int = 0) {
        self.username = username
        self.email = email
        self.friends = friends
        self.createdChallenges = createdChallenges
        self.participatingChallenges = participatingChallenges
        self.privacySettings = privacySettings
        self.pendingFriendRequests = pendingFriendRequests
        self.sentFriendRequests = sentFriendRequests
        self.blockedUsers = blockedUsers
        self.points = points
    }
}

struct PrivacySettings: Codable {
    var showEmail: Bool = false
    var showCreatedChallenges: Bool = true
    var showParticipatingChallenges: Bool = true
}