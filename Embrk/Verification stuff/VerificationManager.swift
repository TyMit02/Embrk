//
//  VerificationManager.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/12/24.
//
import Foundation
import HealthKit
import FirebaseFirestore
import CoreLocation
import os.log

class VerificationManager {
    private let healthKitManager: HealthKitManager
    private let db = Firestore.firestore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VerificationManager")

    init(healthKitManager: HealthKitManager = HealthKitManager.shared) {
        self.healthKitManager = healthKitManager
    }


       private func hasVerifiedToday(challengeId: String, userId: String) async throws -> Bool {
           do {
               let document = try await db.collection("challengeProgress")
                   .document(challengeId)
                   .collection("userProgress")
                   .document(userId)
                   .getDocument()

               if let data = document.data(),
                  let lastVerificationDate = data["lastVerificationDate"] as? Timestamp {
                   return Calendar.current.isDateInToday(lastVerificationDate.dateValue())
               }
               return false
           } catch {
               logger.error("Error checking verification status: \(error.localizedDescription)")
               throw VerificationError.dataFetchFailed
           }
       }
    private func performVerification(challenge: Challenge, user: User) async throws -> Bool {
        switch challenge.challengeType {
        case .fitness:
            return try await verifyFitnessChallenge(challenge)
        case .education:
            return try await verifyEducationChallenge(challenge, user: user)
        case .lifestyle:
            return try await verifyLifestyleChallenge(challenge, user: user)
        case .miscellaneous:
            return try await verifyMiscellaneousChallenge(challenge, user: user)
        }
    }
    
    func verifyChallenge(_ challenge: Challenge, for user: User) async throws -> Bool {
          logger.info("Starting verification for challenge: \(challenge.id ?? "unknown"), type: \(challenge.challengeType.rawValue)")
          
          switch challenge.challengeType {
          case .fitness:
              return try await verifyFitnessChallenge(challenge)
          case .education:
              return try await verifyEducationChallenge(challenge, user: user)
          case .lifestyle:
              return try await verifyLifestyleChallenge(challenge, user: user)
          case .miscellaneous:
              return try await verifyMiscellaneousChallenge(challenge, user: user)
          }
      }

        private func verifyFitnessChallenge(_ challenge: Challenge) async throws -> Bool {
            guard let metric = challenge.healthKitMetric,
                  let goal = challenge.verificationGoal else {
                throw VerificationError.invalidChallengeConfiguration
            }

            let value = try await fetchHealthData(for: metric)
            return value >= goal
        }

        private func fetchHealthData(for metric: HealthKitMetric) async throws -> Double {
            switch metric {
            case .steps:
                return try await healthKitManager.getStepCount(for: Date())
            case .heartRate:
                return try await healthKitManager.getAverageHeartRate(for: Date())
            case .activeEnergy:
                return try await healthKitManager.getActiveEnergyBurned(for: Date())
            case .distance:
                return try await healthKitManager.getDistance(for: Date())
            case .workoutTime:
                return try await healthKitManager.getWorkoutTime(for: Date())
            }
        }

    private func verifyEducationChallenge(_ challenge: Challenge, user: User) async throws -> Bool {
           guard let dailyGoal = challenge.dailyGoal else {
               logger.error("Invalid challenge configuration: missing daily goal")
               throw VerificationError.invalidChallengeConfiguration
           }

           let progress = try await fetchUserReportedProgress(for: challenge.id!, userId: user.id!)
           logger.info("Education challenge progress: \(progress), goal: \(dailyGoal)")
           return progress >= dailyGoal
       }

       private func verifyLifestyleChallenge(_ challenge: Challenge, user: User) async throws -> Bool {
           guard let dailyGoal = challenge.dailyGoal else {
               logger.error("Invalid challenge configuration: missing daily goal")
               throw VerificationError.invalidChallengeConfiguration
           }

           if challenge.lifestyleType == .sleep {
               let sleepHours = try await healthKitManager.getSleepHours(for: Date())
               logger.info("Sleep challenge progress: \(sleepHours) hours, goal: \(Double(dailyGoal) / 60.0) hours")
               return sleepHours >= Double(dailyGoal) / 60.0 // Convert minutes to hours
           } else {
               let progress = try await fetchUserReportedProgress(for: challenge.id!, userId: user.id!)
               logger.info("Lifestyle challenge progress: \(progress), goal: \(dailyGoal)")
               return progress >= dailyGoal
           }
       }

       private func verifyMiscellaneousChallenge(_ challenge: Challenge, user: User) async throws -> Bool {
           guard let verificationMethod = challenge.verificationMethod else {
               logger.error("Invalid challenge configuration: missing verification method")
               throw VerificationError.invalidChallengeConfiguration
           }

           switch verificationMethod {
           case .manual:
               logger.info("Manual verification, always passes")
               return true
           case .photo:
               let result = try await hasUploadedPhotoToday(for: challenge.id!, userId: user.id!)
               logger.info("Photo verification result: \(result)")
               return result
           case .geolocation:
               let result = try await hasCheckedInToday(for: challenge.id!, userId: user.id!)
               logger.info("Geolocation verification result: \(result)")
               return result
           case .timeBased:
               let loggedTime = try await fetchUserReportedProgress(for: challenge.id!, userId: user.id!)
               logger.info("Time-based challenge progress: \(loggedTime), goal: \(challenge.dailyGoal ?? 0)")
               return loggedTime >= (challenge.dailyGoal ?? 0)
           }
       }

       private func fetchUserReportedProgress(for challengeId: String, userId: String) async throws -> Int {
           let document = try await db.collection("challengeProgress")
               .document(challengeId)
               .collection("userProgress")
               .document(userId)
               .getDocument()

           let progress = document.data()?["todayProgress"] as? Int ?? 0
           logger.info("Fetched user progress for challenge \(challengeId), user \(userId): \(progress)")
           return progress
       }


      
       
    private func hasUploadedPhotoToday(for challengeId: String, userId: String) async throws -> Bool {
        do {
            let document = try await db.collection("challengeVerification")
                .document(challengeId)
                .collection("photoUploads")
                .document(userId)
                .getDocument()

            if let data = document.data(),
               let lastUploadDate = data["lastUploadDate"] as? Timestamp {
                return Calendar.current.isDateInToday(lastUploadDate.dateValue())
            } else {
                logger.notice("No photo upload found for user \(userId) in challenge \(challengeId)")
                return false
            }
        } catch {
            logger.error("Error checking photo upload: \(error.localizedDescription)")
            throw VerificationError.dataFetchFailed
        }
    }

    private func hasCheckedInToday(for challengeId: String, userId: String) async throws -> Bool {
        do {
            let document = try await db.collection("challengeVerification")
                .document(challengeId)
                .collection("locationCheckIns")
                .document(userId)
                .getDocument()

            if let data = document.data(),
               let lastCheckInDate = data["lastCheckInDate"] as? Timestamp {
                return Calendar.current.isDateInToday(lastCheckInDate.dateValue())
            } else {
                logger.notice("No location check-in found for user \(userId) in challenge \(challengeId)")
                return false
            }
        } catch {
            logger.error("Error checking location check-in: \(error.localizedDescription)")
            throw VerificationError.dataFetchFailed
        }
    }

    func updateChallengeProgress(challengeId: String, userId: String, progress: Int = 1) async throws {
        do {
            try await db.collection("challengeProgress")
                .document(challengeId)
                .collection("userProgress")
                .document(userId)
                .setData([
                    "todayProgress": progress,
                    "lastVerificationDate": Timestamp(date: Date())
                ], merge: true)
            
            logger.info("Updated challenge progress for challenge: \(challengeId), user: \(userId)")
        } catch {
            logger.error("Error updating challenge progress: \(error.localizedDescription)")
            throw VerificationError.dataUpdateFailed
        }
    }


    func recordPhotoUpload(challengeId: String, userId: String) async throws {
        do {
            try await db.collection("challengeVerification")
                .document(challengeId)
                .collection("photoUploads")
                .document(userId)
                .setData([
                    "lastUploadDate": Timestamp(date: Date())
                ], merge: true)
            
            logger.info("Recorded photo upload for challenge: \(challengeId), user: \(userId)")
        } catch {
            logger.error("Error recording photo upload: \(error.localizedDescription)")
            throw VerificationError.dataUpdateFailed
        }
    }

    func recordLocationCheckIn(challengeId: String, userId: String, location: GeoPoint) async throws {
        do {
            try await db.collection("challengeVerification")
                .document(challengeId)
                .collection("locationCheckIns")
                .document(userId)
                .setData([
                    "lastCheckInDate": Timestamp(date: Date()),
                    "location": location
                ], merge: true)
            
            logger.info("Recorded location check-in for challenge: \(challengeId), user: \(userId)")
        } catch {
            logger.error("Error recording location check-in: \(error.localizedDescription)")
            throw VerificationError.dataUpdateFailed
        }
    }
}

enum VerificationError: Error {
    case invalidData
    case invalidChallengeConfiguration
    case unsupportedMetric
    case healthKitDataFetchFailed
    case alreadyVerifiedToday
    case verificationFailed
    case dataFetchFailed
    case dataUpdateFailed
    case healthKitNotAvailable
    case healthKitAuthorizationNotDetermined(type: HKObjectType)
    case healthKitAuthorizationDenied(type: HKObjectType)
    case unknownAuthorizationStatus
    case noDataAvailable
}

extension VerificationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return NSLocalizedString("Invalid challenge or user data.", comment: "")
        case .invalidChallengeConfiguration:
            return NSLocalizedString("The challenge is not configured correctly.", comment: "")
        case .unsupportedMetric:
            return NSLocalizedString("The specified health metric is not supported.", comment: "")
        case .healthKitDataFetchFailed:
            return NSLocalizedString("Failed to fetch health data. Please check your permissions.", comment: "")
        case .alreadyVerifiedToday:
            return NSLocalizedString("You have already verified your progress for today.", comment: "")
        case .verificationFailed:
            return NSLocalizedString("Verification failed. Please try again later.", comment: "")
        case .dataFetchFailed:
            return NSLocalizedString("Failed to fetch verification data. Please try again later.", comment: "")
        case .dataUpdateFailed:
            return NSLocalizedString("Failed to update verification data. Please try again later.", comment: "")
        case .healthKitNotAvailable:
            return NSLocalizedString("HealthKit is not available on this device.", comment: "")
        case .healthKitAuthorizationDenied:
            return NSLocalizedString("HealthKit permissions have been denied", comment: "")
        case .unknownAuthorizationStatus:
            return NSLocalizedString("HealthKit authorization status is unknown", comment: "")
        case .healthKitAuthorizationNotDetermined:
            return NSLocalizedString("HealthKit authorization status is not determined for", comment: "")
        case .noDataAvailable:
            return NSLocalizedString("No data available", comment: "")
        }
    }
}
