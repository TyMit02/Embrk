import SwiftUI

struct ChallengeCard: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.colorScheme) var colorScheme
    let challenge: Challenge

    var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : Color(hex: "F2F2F7")
    }

    var body: some View {
        NavigationLink(destination: ChallengeDetailsView(challenge: challenge, challengeManager: challengeManager)) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(challenge.title)
                    .font(AppFonts.headline)
                    .foregroundColor(colorScheme == .dark ? .white : AppColors.text)
                    .lineLimit(1)
                
                if let creator = challengeManager.getUser(by: challenge.creatorId) {
                    Text(creator.username)
                        .font(AppFonts.caption)
                        .foregroundColor(colorScheme == .dark ? Color(hex: "8E8E93") : AppColors.lightText)
                } else if challenge.isOfficial {
                    Text("Official Challenge")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondary)
                }

                Text(challenge.description)
                    .font(AppFonts.subheadline)
                    .foregroundColor(colorScheme == .dark ? Color(hex: "8E8E93") : AppColors.lightText)
                    .lineLimit(2)

                HStack {
                    Label(challenge.difficulty, systemImage: "star.fill")
                        .font(AppFonts.footnote)
                        .foregroundColor(AppColors.yellow)

                    Spacer()

                    Label("Max: \(challenge.maxParticipants)", systemImage: "person.fill")
                        .font(AppFonts.footnote)
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(AppSpacing.medium)
            .background(cardBackground)
            .cornerRadius(15)
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.2),
                    radius: 5, x: 0, y: 3)
        }
        .frame(width: 180, height: 180)
    }
}

struct ChallengeCard_Previews: PreviewProvider {
    static var previews: some View {
        let challenge = Challenge(
            title: "30-Day Fitness Challenge",
            description: "Complete daily workouts for 30 days to improve your overall fitness and establish a healthy routine.",
            difficulty: "Medium",
            maxParticipants: 1500,
            isOfficial: true,
            durationInDays: 30,
            creatorId: "official-challenge",
            challengeType: .fitness
        )
        
        Group {
            ChallengeCard(challenge: challenge)
                .environmentObject(ChallengeManager())
                .previewDisplayName("Light Mode")

            ChallengeCard(challenge: challenge)
                .environmentObject(ChallengeManager())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
