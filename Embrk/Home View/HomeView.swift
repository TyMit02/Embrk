//
//  HomeView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/8/24.
//


import SwiftUI

struct HomeView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @Binding var showMenu: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                if challengeManager.isLoading {
                    ProgressView()
                } else if let error = challengeManager.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.large) {
                            headerSection
                            welcomeSection
                            featuredChallengeSection
                            challengesSection
                            ActivityFeed()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                challengeManager.loadChallenges()
                challengeManager.fetchRecentActivities()
            }
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut) {
                    showMenu.toggle()
                }
            }) {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(AppColors.text)
                    .font(.title2)
            }
            
            Spacer()
            
            Text("Challenges")
                .font(AppFonts.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primary)
            
            Spacer()
            
            NavigationLink(destination: AddChallengeView()) {
                Image(systemName: "plus")
                    .foregroundColor(AppColors.primary)
                    .font(.title2)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Welcome back,")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.text)
            Text(authManager.currentUser?.username ?? "Guest")
                .font(AppFonts.title1)
                .foregroundColor(AppColors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var featuredChallengeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Featured Challenge")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            if let featuredChallenge = challengeManager.challenges.first(where: { $0.isOfficial }) {
                NavigationLink(destination: ChallengeDetailsView(challenge: featuredChallenge)) {
                    FeaturedChallengeCard(challenge: featuredChallenge)
                }
            } else {
                Text("No featured challenge available")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.lightText)
            }
        }
    }
    
    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Picker("Challenge Type", selection: $selectedTab) {
                Text("Official").tag(0)
                Text("Community").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if selectedTab == 0 {
                challengeList(challenges: challengeManager.challenges.filter { $0.isOfficial })
            } else {
                challengeList(challenges: challengeManager.challenges.filter { !$0.isOfficial })
            }
        }
    }
    
    private func challengeList(challenges: [Challenge]) -> some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.medium) {
                    ForEach(challenges) { challenge in
                        NavigationLink(destination: ChallengeDetailsView(challenge: challenge).environmentObject(challengeManager)) {
                            ChallengeCard(challenge: challenge)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }

    
    private var trendingUsersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Trending Users")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.medium) {
                    ForEach(challengeManager.users.prefix(5), id: \.id) { user in
                        UserAvatar(user: user)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 120)
        }
    }
}

struct FeaturedChallengeCard: View {
    let challenge: Challenge
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(challenge.title)
                .font(AppFonts.title3)
                .foregroundColor(colorScheme == .dark ? .white : AppColors.text)
            
            Text(challenge.description)
                .font(AppFonts.body)
                .foregroundColor(colorScheme == .dark ? Color(hex: "8E8E93") : AppColors.lightText)
                .lineLimit(2)
            
            HStack {
                Label(challenge.difficulty, systemImage: "star.fill")
                    .font(AppFonts.footnote)
                    .foregroundColor(AppColors.yellow)
                
                Spacer()
                
                Text("Join Now")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
}

struct UserAvatar: View {
    let user: User
    
    var body: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(AppColors.primary)
            
            Text(user.username)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.text)
        }
    }
}
