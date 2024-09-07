
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.yourapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead, completion: completion)
    }
    
    func queryHealthData(for metric: HealthKitMetric, start: Date, end: Date, completion: @escaping (Double?, Error?) -> Void) {
        guard let quantityType = metric.healthKitQuantityType else {
            completion(nil, NSError(domain: "com.yourapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid HealthKit metric"]))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, error)
                return
            }
            
            let value = sum.doubleValue(for: self.unit(for: metric))
            completion(value, nil)
        }
        
        healthStore.execute(query)
    }
    
    func verifyChallenge(_ challenge: Challenge, completion: @escaping (Bool, Error?) -> Void) {
            guard let healthKitMetric = challenge.healthKitMetric,
                  let quantityType = healthKitMetric.healthKitQuantityType else {
                completion(false, NSError(domain: "com.yourapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid HealthKit metric"]))
                return
            }

            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)

            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                guard let result = result, let sum = result.sumQuantity() else {
                    completion(false, error)
                    return
                }

                let value = sum.doubleValue(for: self.unit(for: healthKitMetric))
                let goalReached = challenge.verificationGoal != nil ? value >= challenge.verificationGoal! : true
                completion(goalReached, nil)
            }

            healthStore.execute(query)
        }

        func startMonitoringForAutoVerification(_ challenge: Challenge, completion: @escaping (Bool) -> Void) {
            guard let healthKitMetric = challenge.healthKitMetric,
                  let quantityType = healthKitMetric.healthKitQuantityType,
                  let verificationGoal = challenge.verificationGoal else {
                return
            }

            let query = HKObserverQuery(sampleType: quantityType, predicate: nil) { _, _, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                self.verifyChallenge(challenge) { goalReached, _ in
                    if goalReached {
                        completion(true)
                    }
                }
            }

            healthStore.execute(query)
        }
    
    private func unit(for metric: HealthKitMetric) -> HKUnit {
        switch metric {
        case .steps:
            return .count()
        case .heartRate:
            return HKUnit.count().unitDivided(by: .minute())
        case .activeEnergy:
            return .kilocalorie()
        case .distance:
            return .meter()
        case .workoutTime:
            return .minute()
        }
    }
}
