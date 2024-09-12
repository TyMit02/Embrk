//
//  ProfileView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/8/24.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: AppSpacing.large) {
                        profileHeaderSection
                        statsSection
                        challengeTabsSection
                        selectedChallengesSection
                        achievementsSection
                    }
                    .padding()
                }
                .padding(.bottom, 100)
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: settingsButton)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                if let userId = authManager.currentUser?.id {
                    challengeManager.loadUserChallenges(for: userId)
                }
            }
        }
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
            
            Text(authManager.currentUser?.username ?? "Guest")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.text)
            
            Text(authManager.currentUser?.email ?? "")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.lightText)
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var statsSection: some View {
           HStack(spacing: AppSpacing.medium) {
               statItem(title: "Joined", value: "\(challengeManager.joinedChallenges.count)")
               statItem(title: "Completed", value: "\(challengeManager.completedChallenges.count)")
               statItem(title: "Created", value: "\(challengeManager.createdChallenges.count)")
           }
       }
    
    
    
    private func statItem(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var challengeTabsSection: some View {
        Picker("Challenge Type", selection: $selectedTab) {
            Text("Joined").tag(0)
            Text("Completed").tag(1)
            Text("Created").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    private var selectedChallengesSection: some View {
           VStack(alignment: .leading, spacing: AppSpacing.medium) {
               switch selectedTab {
               case 0:
                   challengeList(title: "Joined Challenges", challenges: challengeManager.joinedChallenges)
               case 1:
                   challengeList(title: "Completed Challenges", challenges: challengeManager.completedChallenges)
               case 2:
                   challengeList(title: "Created Challenges", challenges: challengeManager.createdChallenges)
               default:
                   EmptyView()
               }
           }
       }
    
    private func challengeList(title: String, challenges: [Challenge]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            if challenges.isEmpty {
                Text("No challenges to display")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.lightText)
                    .padding()
            } else {
                ForEach(challenges.prefix(3)) { challenge in
                    NavigationLink(destination: ChallengeDetailsView(challenge: challenge)) {
                        ChallengeRow(challenge: challenge)
                    }
                }
                if challenges.count > 3 {
                    NavigationLink(destination: ChallengeListView(title: title, challenges: challenges)) {
                        Text("See all")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.primary)
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
                .foregroundColor(AppColors.primary)
            
            Text("Coming soon!")
                .font(AppFonts.body)
                .foregroundColor(AppColors.lightText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var settingsButton: some View {
        Button(action: { showSettings = true }) {
            Image(systemName: "gearshape.fill")
                .foregroundColor(AppColors.primary)
        }
    }
}

struct ChallengeRow: View {
    let challenge: Challenge
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: challengeTypeIcon)
                .foregroundColor(AppColors.primary)
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
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.lightText)
        }
        .padding(.vertical, 8)
    }
    
    private var challengeTypeIcon: String {
        switch challenge.challengeType {
        case .fitness:
            return "figure.walk"
        case .education:
            return "book.fill"
        case .lifestyle:
            return "heart.fill"
        case .miscellaneous:
            return "star.fill"
        }
    }
}

struct ChallengeListView: View {
    let title: String
    let challenges: [Challenge]
    
    var body: some View {
        List(challenges) { challenge in
            NavigationLink(destination: ChallengeDetailsView(challenge: challenge)) {
                ChallengeRow(challenge: challenge)
            }
        }
        .navigationTitle(title)
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings View - Coming Soon")
    }
}

//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileView()
//            .environmentObject(AuthManager())
//            .environmentObject(ChallengeManager())
//    }
//}
