
import Foundation
import SwiftUI
import CoreLocation


class EducationVerificationManager: ObservableObject {
    @Published var verifications: [String: [EducationVerification]] = [:]
    
    struct EducationVerification: Identifiable, Codable {
        let id: String
        let challengeId: String
        let userId: String
        let date: Date
        let amount: Int
        let notes: String?
        let evidenceImageURL: URL?
    }
    
    func addVerification(for challenge: Challenge, userId: String, amount: Int, notes: String?, evidenceImageURL: URL?) {
        let verification = EducationVerification(
            id: UUID().uuidString,
            challengeId: challenge.id ?? "",
            userId: userId,
            date: Date(),
            amount: amount,
            notes: notes,
            evidenceImageURL: evidenceImageURL
        )
        
        if verifications[challenge.id ?? ""] != nil {
            verifications[challenge.id ?? ""]?.append(verification)
        } else {
            verifications[challenge.id ?? ""] = [verification]
        }
    }
    
    func getVerifications(for challengeId: String) -> [EducationVerification] {
        return verifications[challengeId] ?? []
    }
    
    func getTotalProgress(for challengeId: String, userId: String) -> Int {
        return getVerifications(for: challengeId)
            .filter { $0.userId == userId }
            .reduce(0) { $0 + $1.amount }
    }
}
