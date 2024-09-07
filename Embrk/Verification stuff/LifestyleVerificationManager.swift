import Foundation
import HealthKit

class LifestyleVerificationManager: ObservableObject {
    @Published var verifications: [String: [LifestyleVerification]] = [:]
    private let healthStore = HKHealthStore()
    
    struct LifestyleVerification: Identifiable, Codable {
        let id: String
        let challengeId: String
        let userId: String
        let date: Date
        let amount: Double
        let notes: String?
        let evidenceImageURL: URL?
    }
    
    func verifyChallenge(_ challenge: Challenge, userId: String, amount: Double, notes: String?, evidenceImageURL: URL?, completion: @escaping (Bool, Error?) -> Void) {
        switch challenge.verificationMethod {
        case .healthKit:
            verifyWithHealthKit(challenge, userId: userId, completion: completion)
        case .manual:
            verifyManually(challenge, userId: userId, amount: amount, notes: notes, evidenceImageURL: evidenceImageURL, completion: completion)
        }
    }
    
    private func verifyWithHealthKit(_ challenge: Challenge, userId: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let lifestyleType = challenge.lifestyleType else {
            completion(false, NSError(domain: "com.yourapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid lifestyle type"]))
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        switch lifestyleType {
        case .meditation:
            if let categoryType = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
                queryCategoryData(type: categoryType, start: startOfDay, end: now, challenge: challenge, userId: userId, completion: completion)
            } else {
                completion(false, NSError(domain: "com.yourapp", code: 4, userInfo: [NSLocalizedDescriptionKey: "Mindful session data not available"]))
            }
        case .sleep:
            if let categoryType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                queryCategoryData(type: categoryType, start: startOfDay, end: now, challenge: challenge, userId: userId, completion: completion)
            } else {
                completion(false, NSError(domain: "com.yourapp", code: 5, userInfo: [NSLocalizedDescriptionKey: "Sleep analysis data not available"]))
            }
        case .waterIntake:
            if let quantityType = HKObjectType.quantityType(forIdentifier: .dietaryWater) {
                queryQuantityData(type: quantityType, start: startOfDay, end: now, challenge: challenge, userId: userId, completion: completion)
            } else {
                completion(false, NSError(domain: "com.yourapp", code: 6, userInfo: [NSLocalizedDescriptionKey: "Dietary water data not available"]))
            }
        case .other:
            completion(false, NSError(domain: "com.yourapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit verification not available for this lifestyle type"]))
        }
    }
    
    private func queryCategoryData(type: HKCategoryType, start: Date, end: Date, challenge: Challenge, userId: String, completion: @escaping (Bool, Error?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let samples = samples as? [HKCategorySample], error == nil else {
                completion(false, error)
                return
            }
            
            let totalDuration = samples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            let value = totalDuration / 60 // Convert to minutes
            let goalReached = challenge.verificationGoal != nil ? value >= challenge.verificationGoal! : true
            
            if goalReached {
                self.addVerification(for: challenge, userId: userId, amount: value, notes: nil, evidenceImageURL: nil)
            }
            
            completion(goalReached, nil)
        }
        
        healthStore.execute(query)
    }
    
    private func queryQuantityData(type: HKQuantityType, start: Date, end: Date, challenge: Challenge, userId: String, completion: @escaping (Bool, Error?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(false, error)
                return
            }
            
            let value = sum.doubleValue(for: self.unit(for: challenge.lifestyleType!))
            let goalReached = challenge.verificationGoal != nil ? value >= challenge.verificationGoal! : true
            
            if goalReached {
                self.addVerification(for: challenge, userId: userId, amount: value, notes: nil, evidenceImageURL: nil)
            }
            
            completion(goalReached, nil)
        }
        
        healthStore.execute(query)
    }
    
    private func verifyManually(_ challenge: Challenge, userId: String, amount: Double, notes: String?, evidenceImageURL: URL?, completion: @escaping (Bool, Error?) -> Void) {
        let goalReached = challenge.verificationGoal != nil ? amount >= challenge.verificationGoal! : true
        
        if goalReached {
            addVerification(for: challenge, userId: userId, amount: amount, notes: notes, evidenceImageURL: evidenceImageURL)
        }
        
        completion(goalReached, nil)
    }
    
    private func addVerification(for challenge: Challenge, userId: String, amount: Double, notes: String?, evidenceImageURL: URL?) {
        let verification = LifestyleVerification(
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
    
    func getVerifications(for challengeId: String) -> [LifestyleVerification] {
        return verifications[challengeId] ?? []
    }
    
    func getTotalProgress(for challengeId: String, userId: String) -> Double {
        return getVerifications(for: challengeId)
            .filter { $0.userId == userId }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func unit(for lifestyleType: Challenge.LifestyleType) -> HKUnit {
        switch lifestyleType {
        case .meditation, .sleep:
            return .minute()
        case .waterIntake:
            return .literUnit(with: .milli)
        case .other:
            return .count()
        }
    }
}
