import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var showingAddChallenge = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    welcomeSection
                    activeChallengesSection
                    featuredChallengeSection
                }
                .padding()
            }
            .background(AppColors.background.edgesIgnoringSafeArea(.all))
            .navigationTitle("Home")
            .navigationBarItems(trailing: addButton)
        }
        .sheet(isPresented: $showingAddChallenge) {
            AddChallengeView()
        }
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Welcome back,")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.text)
            Text(authManager.currentUser?.username ?? "")
                .font(AppFonts.title1)
                .foregroundColor(AppColors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(15)
    }
    
    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Active Challenges")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            if challengeManager.activeChallenges.isEmpty {
                Text("You're not participating in any challenges yet.")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.lightText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.medium) {
                        ForEach(challengeManager.activeChallenges) { challenge in
                            ChallengeCard(challenge: challenge)
                        }
                    }
                }
            }
        }
    }
    
    private var featuredChallengeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Featured Challenge")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            if let featuredChallenge = challengeManager.featuredChallenge {
                FeaturedChallengeCard(challenge: featuredChallenge)
            } else {
                Text("No featured challenge available.")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.lightText)
            }
        }
    }
    
    private var addButton: some View {
        Button(action: { showingAddChallenge = true }) {
            Image(systemName: "plus")
        }
    }
}

struct ChallengeCard: View {
    let challenge: Challenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(challenge.title)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            Text(challenge.description)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.lightText)
                .lineLimit(2)
            HStack {
                Text(challenge.difficulty)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondary)
                Spacer()
                Text("\(challenge.durationInDays) days")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding()
        .frame(width: 200)
        .background(AppColors.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct FeaturedChallengeCard: View {
    let challenge: Challenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(challenge.title)
                .font(AppFonts.title3)
                .foregroundColor(AppColors.text)
            Text(challenge.description)
                .font(AppFonts.body)
                .foregroundColor(AppColors.lightText)
            HStack {
                Text(challenge.difficulty)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.secondary)
                Spacer()
                Text("Join Now")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}