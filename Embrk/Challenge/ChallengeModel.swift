//
//  Challenge.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//


import SwiftUI
import Foundation
import HealthKit
import FirebaseFirestore

struct Challenge: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let title: String
    let description: String
    let difficulty: String
    let maxParticipants: Int
    var participatingUsers: [String]
    let isOfficial: Bool
    let durationInDays: Int
    var userProgress: [String: [Timestamp]]
    let creatorId: String
    let challengeType: ChallengeType
    let healthKitMetric: HealthKitMetric?
    let verificationGoal: Double?
    let startDate: Date
    let educationType: EducationType?
    let unitOfMeasurement: String?
    let dailyGoal: Int?
    let lifestyleType: LifestyleType?
    let verificationMethod: VerificationMethod
    

    enum CodingKeys: String, CodingKey {
        case id, title, description, difficulty, maxParticipants, participatingUsers, isOfficial, durationInDays, userProgress, creatorId, challengeType, healthKitMetric, verificationGoal, startDate, educationType, unitOfMeasurement, dailyGoal, lifestyleType, verificationMethod
    }

    enum EducationType: String, Codable, CaseIterable {
        case reading = "Reading"
        case studying = "Studying"
        case languageLearning = "Language Learning"
        case other = "Other"
    }

    enum LifestyleType: String, Codable, CaseIterable {
        case meditation = "Meditation"
        case sleep = "Sleep"
        case waterIntake = "Water Intake"
        case other = "Other"
    }

    enum VerificationMethod: String, Codable, CaseIterable {
        case healthKit = "HealthKit"
        case manual = "Manual"
    }
    
    var currentParticipants: Int {
        participatingUsers.count
    }

    init(title: String, description: String, difficulty: String, maxParticipants: Int, isOfficial: Bool, durationInDays: Int, creatorId: String, challengeType: ChallengeType, healthKitMetric: HealthKitMetric? = nil, verificationGoal: Double? = nil, educationType: EducationType? = nil, unitOfMeasurement: String? = nil, dailyGoal: Int? = nil, lifestyleType: LifestyleType? = nil, verificationMethod: VerificationMethod = .manual, startDate: Date = Date()) {
           self.title = title
           self.description = description
           self.difficulty = difficulty
           self.maxParticipants = maxParticipants
           self.participatingUsers = []
           self.isOfficial = isOfficial
           self.durationInDays = durationInDays
           self.userProgress = [:]
           self.creatorId = creatorId
           self.challengeType = challengeType
           self.healthKitMetric = healthKitMetric
           self.verificationGoal = verificationGoal ?? VerificationGoalDeterminer.determineGoal(title: title, description: description, challengeType: challengeType)
           self.educationType = educationType
           self.unitOfMeasurement = unitOfMeasurement
           self.dailyGoal = dailyGoal
           self.lifestyleType = lifestyleType
           self.verificationMethod = verificationMethod
           self.startDate = startDate
       }
    
    static func == (lhs: Challenge, rhs: Challenge) -> Bool {
        return lhs.id == rhs.id
    }
}

enum ChallengeType: String, Codable, CaseIterable {
    case fitness = "Fitness"
    case education = "Education"
    case miscellaneous = "Miscellaneous"
    case lifestyle = "Lifestyle"
}

enum HealthKitMetric: String, Codable, CaseIterable {
    case steps = "Steps"
    case heartRate = "Heart Rate"
    case activeEnergy = "Active Energy"
    case distance = "Distance"
    case workoutTime = "Workout Time"
    
    var healthKitQuantityType: HKQuantityType? {
        switch self {
        case .steps:
            return HKObjectType.quantityType(forIdentifier: .stepCount)
        case .heartRate:
            return HKObjectType.quantityType(forIdentifier: .heartRate)
        case .activeEnergy:
            return HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        case .distance:
            return HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
        case .workoutTime:
            return HKObjectType.quantityType(forIdentifier: .appleExerciseTime)
        }
    }
}
