import Foundation

struct OfficialChallengeData {
    static let officialChallenges = [
        Challenge(title: "30-Day Fitness", description: "Complete daily workouts for 30 days", difficulty: "Medium",
                  maxParticipants: 1500, isOfficial: true, durationInDays: 30, creatorId: "official-1", challengeType: .fitness),
        Challenge(title: "Learn a Language", description: "Master 100 new words in a month", difficulty: "Hard",
                  maxParticipants: 2000, isOfficial: true, durationInDays: 30, creatorId: "official-2", challengeType: .education),
        Challenge(title: "Meditation Challenge", description: "Meditate for 10 minutes daily", difficulty: "Easy",
                  maxParticipants: 3000, isOfficial: true, durationInDays: 21, creatorId: "official-3", challengeType: .lifestyle),
        Challenge(title: "Coding Sprint", description: "Build a simple app in 7 days", difficulty: "Hard",
                  maxParticipants: 500, isOfficial: true, durationInDays: 7, creatorId: "official-4", challengeType: .education),
        Challenge(title: "Reading Marathon", description: "Read 5 books in a month", difficulty: "Medium",
                  maxParticipants: 1200, isOfficial: true, durationInDays: 30, creatorId: "official-5", challengeType: .education)
    ]
}
