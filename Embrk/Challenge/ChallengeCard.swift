//
//  ChallengeCard.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//


import SwiftUI

struct ChallengeCard: View {
    let challenge: Challenge
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(challenge.title)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
                .lineLimit(1)
            
            Text(challenge.description)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.lightText)
                .lineLimit(2)
            
            HStack {
                difficultyLabel
                Spacer()
                durationLabel
            }
            
            HStack {
                participantsLabel
                Spacer()
                if challenge.isOfficial {
                    officialLabel
                }
            }
        }
        .padding()
        .frame(width: 200, height: 160)
        .background(cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white
    }
    
    private var difficultyLabel: some View {
        Label(challenge.difficulty, systemImage: "star.fill")
            .font(AppFonts.caption)
            .foregroundColor(AppColors.yellow)
    }
    
    private var durationLabel: some View {
        Label("\(challenge.durationInDays) days", systemImage: "calendar")
            .font(AppFonts.caption)
            .foregroundColor(AppColors.primary)
    }
    
    private var participantsLabel: some View {
        Label("\(challenge.participatingUsers.count)/\(challenge.maxParticipants)", systemImage: "person.3.fill")
            .font(AppFonts.caption)
            .foregroundColor(AppColors.secondary)
    }
    
    private var officialLabel: some View {
        Label("Official", systemImage: "checkmark.seal.fill")
            .font(AppFonts.caption)
            .foregroundColor(AppColors.primary)
    }
}

// Preview
struct ChallengeCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChallengeCard(challenge: Challenge(
                title: "30-Day Fitness",
                description: "Get fit in 30 days with daily workouts",
                difficulty: "Medium",
                maxParticipants: 100,
                isOfficial: true,
                durationInDays: 30,
                creatorId: "official",
                challengeType: .fitness
            ))
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Light Mode")
            
            ChallengeCard(challenge: Challenge(
                title: "Learn Swift",
                description: "Master Swift programming in 60 days",
                difficulty: "Hard",
                maxParticipants: 50,
                isOfficial: false,
                durationInDays: 60,
                creatorId: "user123",
                challengeType: .education
            ))
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
