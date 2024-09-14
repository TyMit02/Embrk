//
//  UserProfileView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/12/24.
//


import SwiftUI

struct UserProfileView: View {
    let user: User
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                userHeader
                statsView
                challengeTabs
                selectedChallengesView
            }
            .padding()
            .padding(.bottom, 100)
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .navigationTitle(user.username)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var userHeader: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(AppColors.primary)
            
            Text(user.username)
                .font(AppFonts.title2)
                .foregroundColor(AppColors.text)
            
//            Text(user.email)
//                .font(AppFonts.subheadline)
//                .foregroundColor(AppColors.lightText)
        }
    }
    
    private var statsView: some View {
        HStack {
            statView(title: "Joined", value: "\(joinedChallenges.count)")
            Spacer()
            statView(title: "Created", value: "\(createdChallenges.count)")
            Spacer()
            statView(title: "Completed", value: "\(completedChallenges.count)")
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private func statView(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
        }
    }
    
    private var challengeTabs: some View {
        Picker("Challenge Type", selection: $selectedTab) {
            Text("Joined").tag(0)
            Text("Created").tag(1)
            Text("Completed").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    private var selectedChallengesView: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch selectedTab {
            case 0:
                challengeList(title: "Joined Challenges", challenges: joinedChallenges)
            case 1:
                challengeList(title: "Created Challenges", challenges: createdChallenges)
            case 2:
                challengeList(title: "Completed Challenges", challenges: completedChallenges)
            default:
                EmptyView()
            }
        }
    }
    
    private func challengeList(title: String, challenges: [Challenge]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            if challenges.isEmpty {
                Text("No challenges to display")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.lightText)
            } else {
                ForEach(challenges) { challenge in
                    NavigationLink(destination: ChallengeDetailsView(challenge: challenge)) {
                        WideChallengeCard(challenge: challenge)
                    }
                }
            }
        }
    }
    
    private var joinedChallenges: [Challenge] {
        challengeManager.challenges.filter { challenge in
            user.participatingChallenges.contains(challenge.id ?? "") &&
            !isCompleted(challenge: challenge)
        }
    }
    
    private var createdChallenges: [Challenge] {
        challengeManager.challenges.filter { $0.creatorId == user.id }
    }
    
    private var completedChallenges: [Challenge] {
        challengeManager.challenges.filter { challenge in
            user.participatingChallenges.contains(challenge.id ?? "") &&
            isCompleted(challenge: challenge)
        }
    }
    
    private func isCompleted(challenge: Challenge) -> Bool {
        guard let challengeId = challenge.id else { return false }
        
        let endDate = challenge.startDate.addingTimeInterval(TimeInterval(challenge.durationInDays * 24 * 60 * 60))
        let isExpired = Date() > endDate
        
        let userProgress = challenge.userProgress[user.id ?? ""] ?? []
        let isAllDaysCompleted = userProgress.count >= challenge.durationInDays
        
        return isExpired && isAllDaysCompleted
    }
}

struct WideChallengeCard: View {
    let challenge: Challenge
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(challenge.title)
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
                .lineLimit(1)
            
            Text(challenge.description)
                .font(AppFonts.body)
                .foregroundColor(AppColors.lightText)
                .lineLimit(2)
            
            HStack {
                Label(challenge.difficulty, systemImage: "star.fill")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.yellow)
                
                Spacer()
                
                Label("\(challenge.durationInDays) days", systemImage: "calendar")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.primary)
            }
            
            HStack {
                Label("Participants: \(challenge.participatingUsers.count)/\(challenge.maxParticipants)", systemImage: "person.3.fill")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondary)
                
                Spacer()
                
                if challenge.isOfficial {
                    Label("Official", systemImage: "checkmark.seal.fill")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
