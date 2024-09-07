import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.colorScheme) var colorScheme
    let user: User
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                statisticsSection
                if user.privacySettings.showCreatedChallenges {
                    createdChallengesSection
                }
                if user.privacySettings.showParticipatingChallenges {
                    participatingChallengesSection
                }
                recentActivitySection
            }
            .padding()
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(user.username, displayMode: .inline)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var profileHeader: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(AppColors.primary)
            
            Text(user.username)
                .font(AppFonts.title2)
                .foregroundColor(AppColors.text)
            
            if user.privacySettings.showEmail {
                Text(user.email)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.lightText)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var statisticsSection: some View {
        HStack(spacing: 20) {
            statisticItem(title: "Created", value: "\(challengeManager.getChallengesForUser(user).created.count)")
            statisticItem(title: "Participating", value: "\(challengeManager.getChallengesForUser(user).participating.count)")
            statisticItem(title: "Completed", value: "\(challengeManager.getCompletedChallengesCount(for: user))")
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private func statisticItem(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
        }
    }
    
    private var createdChallengesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Created Challenges")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            let createdChallenges = challengeManager.getChallengesForUser(user).created
            ForEach(createdChallenges) { challenge in
                NavigationLink(destination: ChallengeDetailsView(challenge: challenge, challengeManager: challengeManager)) {
                    ChallengeRow(challenge: challenge)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var participatingChallengesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Participating Challenges")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            let participatingChallenges = challengeManager.getChallengesForUser(user).participating
            ForEach(participatingChallenges) { challenge in
                NavigationLink(destination: ChallengeDetailsView(challenge: challenge, challengeManager: challengeManager)) {
                    ChallengeRow(challenge: challenge)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            ForEach(challengeManager.getRecentActivity(for: user).prefix(5), id: \.self) { activity in
                Text(activity)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.lightText)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
}

struct ChallengeRow: View {
    let challenge: Challenge
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(challenge.title)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                Text(challenge.description)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.lightText)
                    .lineLimit(1)
            }
            Spacer()
            Text(challenge.difficulty)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.secondary)
                .padding(5)
                .background(AppColors.secondary.opacity(0.2))
                .cornerRadius(5)
        }
        .padding(.vertical, 5)
    }
}

//struct UserProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        let challengeManager = ChallengeManager()
//        let user = User(username: "TestUser", email: "test@example.com", password: "password")
//        
//        // Add some sample challenges
//        challengeManager.addChallenge(Challenge(title: "30-Day Fitness", description: "Get fit in 30 days", difficulty: "Medium", maxParticipants: 1000, isOfficial: true, durationInDays: 30, creatorId: user.id, challengeType: .fitness))
//        challengeManager.addChallenge(Challenge(title: "Learn Swift", description: "Master Swift programming", difficulty: "Hard", maxParticipants: 500, isOfficial: false, durationInDays: 60, creatorId: user.id, challengeType: .education))
//        
//        return Group {
//            NavigationView {
//                UserProfileView(user: user)
//                    .environmentObject(challengeManager)
//            }
//            .previewDisplayName("Light Mode")
//            
//            NavigationView {
//                UserProfileView(user: user)
//                    .environmentObject(challengeManager)
//                    .preferredColorScheme(.dark)
//            }
//            .previewDisplayName("Dark Mode")
//        }
//    }
//}
