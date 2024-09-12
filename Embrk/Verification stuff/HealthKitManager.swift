//
//  HealthKitManager.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/11/24.
//


import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "com.yourapp.healthkit", code: 0, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"])
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            // Add other types as needed
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
    
    func getStepCount(for date: Date) async throws -> Double {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: date, end: nil, options: .strictStartDate)
        
        let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics, Error>) in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(domain: "com.yourapp.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "No step count data available"]))
                }
            }
            healthStore.execute(query)
        }
        
        guard let sum = statistics.sumQuantity() else {
            throw NSError(domain: "com.yourapp.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "No step count data available"])
        }
        
        return sum.doubleValue(for: HKUnit.count())
    }
    
    func getActiveEnergyBurned(for date: Date) async throws -> Double {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let predicate = HKQuery.predicateForSamples(withStart: date, end: nil, options: .strictStartDate)
        
        let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics, Error>) in
            let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(domain: "com.yourapp.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey: "No active energy data available"]))
                }
            }
            healthStore.execute(query)
        }
        
        guard let sum = statistics.sumQuantity() else {
            throw NSError(domain: "com.yourapp.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey: "No active energy data available"])
        }
        
        return sum.doubleValue(for: HKUnit.kilocalorie())
    }
    
    func getStepCountAsync(for date: Date) async throws -> Double {
        try await getStepCount(for: date)
    }
   
    func getActiveEnergyBurnedAsync(for date: Date) async throws -> Double {
        try await getActiveEnergyBurned(for: date)
    }
}
