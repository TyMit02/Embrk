import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                profileHeaderSection
               statisticsSection
                currentChallengesSection
                achievementsSection
                settingsSection
                logoutButton
            }
            .padding()
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Profile", displayMode: .inline)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(AppColors.primary)
            
            Text(challengeManager.currentUser?.username ?? "Guest")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.text)
            
            Text(challengeManager.currentUser?.email ?? "")
                .font(AppFonts.body)
                .foregroundColor(AppColors.lightText)
            
            Button("Edit Profile") {
                showingEditProfile = true
            }
            .font(AppFonts.headline)
            .foregroundColor(AppColors.primary)
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
   private var statisticsSection: some View {
               VStack(alignment: .leading, spacing: AppSpacing.small) {
                   Text("Statistics")
                       .font(AppFonts.headline)
                       .foregroundColor(AppColors.text)
                   
                   HStack {
                              statisticItem(title: "Challenges", value: "\(challengeManager.getUserChallenges().count)")
                              Spacer()
                              statisticItem(title: "Completed", value: "\(challengeManager.getCompletedChallenges().count)")
                              Spacer()
                              statisticItem(title: "Streak", value: "\(challengeManager.getCurrentStreak()) days")
                          }
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
    
    private var currentChallengesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Current Challenges")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                             HStack(spacing: AppSpacing.medium) {
                                 ForEach(challengeManager.getUserChallenges()) { challenge in
                                                    NavigationLink(destination: ChallengeDetailsView(challenge: challenge, challengeManager: challengeManager)) {
                                                        ChallengeCard(challenge: challenge)
                                    }
                                 }
                             }
                         }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Achievements")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            HStack {
                ForEach(0..<3) { _ in
                    Image(systemName: "medal.fill")
                        .font(.largeTitle)
                        .foregroundColor(AppColors.yellow)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var settingsSection: some View {
        Button(action: {
            showingSettings = true
        }) {
            HStack {
                Text("Settings")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.lightText)
            }
            .padding()
            .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
            .cornerRadius(15)
        }
    }
    
    private var logoutButton: some View {
        Button(action: {
            challengeManager.logOut()
        }) {
            Text("Log Out")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(15)
        }
    }
}
//
//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        let challengeManager = ChallengeManager()
//        challengeManager.setCurrentUser(User(username: "TestUser", email: "test@example.com", password: "password"))
//        // Add some test challenges to the user
//        let testChallenge1 = Challenge(title: "30-Day Fitness", description: "Daily workouts", difficulty: "Medium", maxParticipants: 1000, isOfficial: true, durationInDays: 30, creatorId: UUID(), challengeType: .fitness)
//        let testChallenge2 = Challenge(title: "Learn Swift", description: "Code every day", difficulty: "Hard", maxParticipants: 500, isOfficial: false, durationInDays: 31, creatorId: UUID(), challengeType: .education)
//        challengeManager.addChallenge(testChallenge1)
//        challengeManager.addChallenge(testChallenge2)
//        
//        return Group {
//            NavigationView {
//                ProfileView()
//                    .environmentObject(challengeManager)
//            }
//            .previewDisplayName("Light Mode")
//            
//            NavigationView {
//                ProfileView()
//                    .environmentObject(challengeManager)
//                    .preferredColorScheme(.dark)
//            }
//            .previewDisplayName("Dark Mode")
//        }
//    }
//}
