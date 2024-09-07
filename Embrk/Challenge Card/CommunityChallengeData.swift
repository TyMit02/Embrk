//
//  CommunityChallengeData.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/7/24.
//



import Foundation

struct CommunityChallengeData {
    static let communityChallenges = [
        Challenge(title: "Zero Waste Month", description: "Reduce your household waste to zero for 30 days", difficulty: "Hard",
                  maxParticipants: 1200, isOfficial: false, durationInDays: 30, creatorId: "community-1", challengeType: .fitness),
        Challenge(title: "Digital Detox", description: "Limit screen time to 1 hour per day for 2 weeks", difficulty: "Medium",
                  maxParticipants: 2500, isOfficial: false, durationInDays: 14, creatorId: "community-2", challengeType: .fitness),
        Challenge(title: "Random Acts of Kindness", description: "Perform one kind act daily for a month", difficulty: "Easy",
                  maxParticipants: 3500, isOfficial: false, durationInDays: 31, creatorId: "community-3", challengeType: .fitness),
        Challenge(title: "Home Chef Challenge", description: "Cook a new recipe every day for a week", difficulty: "Medium",
                  maxParticipants: 1800, isOfficial: false, durationInDays: 7, creatorId: "community-4", challengeType: .fitness),
        Challenge(title: "30-Day Yoga Journey", description: "Practice yoga for 30 minutes daily", difficulty: "Easy",
                  maxParticipants: 2200, isOfficial: false, durationInDays: 30, creatorId: "community-5", challengeType: .fitness)
    ]
}
