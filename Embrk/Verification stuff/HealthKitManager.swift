//
//  HealthKitManager.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/11/24.
//


import HealthKit
import os.log

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "HealthKitManager")
    
    func requestAuthorization() async throws {
          logger.info("Requesting HealthKit authorization")
          let typesToRead: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
                       HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                       HKObjectType.quantityType(forIdentifier: .heartRate)!,
                       HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                       HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
                       HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
          ]
          
          do {
              try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
              logger.info("HealthKit authorization request completed")
              for type in typesToRead {
                  let status = healthStore.authorizationStatus(for: type)
                  logger.info("Authorization status for \(type.identifier): \(status.rawValue)")
              }
          } catch {
              logger.error("HealthKit authorization failed: \(error.localizedDescription)")
              throw error
          }
      }
  
    func checkAuthorization(for types: Set<HKSampleType>) async throws {
           logger.info("Checking HealthKit authorization")
           for type in types {
               let status = healthStore.authorizationStatus(for: type)
               logger.info("Authorization status for \(type.identifier): \(status.rawValue)")
               switch status {
               case .sharingAuthorized:
                   logger.info("Authorization granted for \(type.identifier)")
               case .sharingDenied:
                   logger.error("Authorization explicitly denied for \(type.identifier)")
                   throw HealthKitError.authorizationDenied
               case .notDetermined:
                   logger.info("Authorization not determined for \(type.identifier). Requesting authorization...")
                   try await requestAuthorization()
                   return try await checkAuthorization(for: types)  // Recursive call after requesting authorization
               @unknown default:
                   logger.error("Unknown authorization status for \(type.identifier)")
                   throw HealthKitError.unknownAuthorizationStatus
               }
           }
           logger.info("All required HealthKit permissions are granted")
       }
    
    func testHealthKitAccess() async -> String {
         let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
         let now = Date()
         let startOfDay = Calendar.current.startOfDay(for: now)
         let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

         do {
             let rawStatus = healthStore.authorizationStatus(for: stepType)
             logger.info("Raw HKAuthorizationStatus: \(rawStatus.rawValue)")

             let query = HKSampleQuery(sampleType: stepType, predicate: predicate, limit: 1, sortDescriptors: nil) { (query, samples, error) in
                 if let error = error {
                     self.logger.error("Error querying HealthKit: \(error.localizedDescription)")
                 } else if let samples = samples, !samples.isEmpty {
                     self.logger.info("Successfully queried HealthKit data")
                 } else {
                     self.logger.info("No HealthKit data available for the specified period")
                 }
             }

             try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                 healthStore.execute(query)
                 continuation.resume()
             }

             return "HealthKit query executed successfully"
         } catch {
             return "Error testing HealthKit access: \(error.localizedDescription)"
         }
     }
    
    func getAverageHeartRate(for date: Date) async throws -> Double {
           let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
           let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: date), end: date, options: .strictStartDate)
           
           let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics, Error>) in
               let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, error in
                   if let error = error {
                       continuation.resume(throwing: error)
                   } else if let result = result {
                       continuation.resume(returning: result)
                   } else {
                       continuation.resume(throwing: HealthKitError.dataNotAvailable)
                   }
               }
               healthStore.execute(query)
           }
           
           guard let average = statistics.averageQuantity() else {
               throw HealthKitError.dataNotAvailable
           }
           
           return average.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
       }

       func getDistance(for date: Date) async throws -> Double {
           let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
           let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: date), end: date, options: .strictStartDate)
           
           let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics, Error>) in
               let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                   if let error = error {
                       continuation.resume(throwing: error)
                   } else if let result = result {
                       continuation.resume(returning: result)
                   } else {
                       continuation.resume(throwing: HealthKitError.dataNotAvailable)
                   }
               }
               healthStore.execute(query)
           }
           
           guard let sum = statistics.sumQuantity() else {
               throw HealthKitError.dataNotAvailable
           }
           
           return sum.doubleValue(for: HKUnit.meter())
       }

       func getWorkoutTime(for date: Date) async throws -> Double {
           let workoutTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
           let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: date), end: date, options: .strictStartDate)
           
           let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics, Error>) in
               let query = HKStatisticsQuery(quantityType: workoutTimeType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                   if let error = error {
                       continuation.resume(throwing: error)
                   } else if let result = result {
                       continuation.resume(returning: result)
                   } else {
                       continuation.resume(throwing: HealthKitError.dataNotAvailable)
                   }
               }
               healthStore.execute(query)
           }
           
           guard let sum = statistics.sumQuantity() else {
               throw HealthKitError.dataNotAvailable
           }
           
           return sum.doubleValue(for: HKUnit.minute())
       }
    
    
    func getStepCount(for date: Date) async throws -> Double {
           logger.info("Fetching step count for \(date)")
           let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
           
           // Use a wider date range: from 7 days ago to now
           let calendar = Calendar.current
           let startOfDay = calendar.startOfDay(for: date)
           let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
           let startDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
           
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

           let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics, Error>) in
               let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                   if let error = error {
                       self.logger.error("Error fetching step count: \(error.localizedDescription)")
                       continuation.resume(throwing: error)
                   } else if let result = result, let sum = result.sumQuantity() {
                       self.logger.info("Successfully fetched step count")
                       continuation.resume(returning: result)
                   } else {
                       self.logger.error("No step count data available")
                       continuation.resume(throwing: HealthKitError.dataNotAvailable)
                   }
               }
               healthStore.execute(query)
           }
           
           let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
           logger.info("Fetched step count: \(steps)")
           return steps
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
    
    func getSleepHours(for date: Date) async throws -> Double {
            let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            let predicate = HKQuery.predicateForSamples(withStart: date, end: Date(), options: .strictStartDate)
            
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples ?? [])
                    }
                }
                healthStore.execute(query)
            }
            
            let sleepHours = samples.reduce(0.0) { total, sample in
                guard let sleepSample = sample as? HKCategorySample else { return total }
                return total + sleepSample.endDate.timeIntervalSince(sleepSample.startDate) / 3600.0
            }
            
            return sleepHours
        }
}
enum HealthKitError: Error {
    case notAvailable
    case authorizationDenied
    case dataNotAvailable
    case unknownAuthorizationStatus
}
