//
//  SearchView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var searchText = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var searchScope = 0 // 0 for Users, 1 for Challenges
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                segmentedControl
                Spacer().frame(height: 20)
                if searchScope == 0 {
                    userList
                } else {
                    challengeList
                }
            }
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Search", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Friend Request"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var searchBar: some View {
        TextField("Search", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
    }
    
    private var segmentedControl: some View {
        Picker("Search Scope", selection: $searchScope) {
            Text("Users").tag(0)
            Text("Challenges").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
    }
    
    private var userList: some View {
           ScrollView {
               LazyVStack(spacing: AppSpacing.medium) {
                   ForEach(filteredUsers, id: \.id) { user in
                       NavigationLink(destination: UserProfileView(user: user)) {
                           userCard(for: user)
                       }
                   }
               }
               .padding()
           }
       }
    
    private func userCard(for user: User) -> some View {
          VStack(alignment: .leading, spacing: 10) {
              HStack {
                  Image(systemName: "person.circle.fill")
                      .resizable()
                      .frame(width: 60, height: 60)
                      .foregroundColor(AppColors.primary)
                  VStack(alignment: .leading) {
                      Text(user.username)
                          .font(AppFonts.headline)
                          .foregroundColor(AppColors.text)
//                      Text(user.email)
//                          .font(AppFonts.subheadline)
//                          .foregroundColor(AppColors.lightText)
                  }
                  Spacer()
                  Image(systemName: "chevron.right")
                      .foregroundColor(AppColors.lightText)
              }
              
//              HStack {
//                  statView(title: "Joined", value: "\(user.participatingChallenges.count)")
//                  Spacer()
//                  statView(title: "Created", value: "\(user.createdChallenges.count)")
//                  Spacer()
//                  statView(title: "Completed", value: "0") // You might want to add a property for completed challenges
//              }
          }
          .padding()
          .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
          .cornerRadius(15)
          .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
    
    private var challengeList: some View {
            ScrollView {
                LazyVStack(spacing: AppSpacing.medium) {
                    ForEach((filteredChallenges), id: \.id) { challenge in
                        NavigationLink(destination: ChallengeDetailsView(challenge: challenge)) {
                            WideChallengeCard(challenge: challenge)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    
    private struct WideChallengeCard: View {
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
    
    private var filteredUsers: [User] {
        if searchText.isEmpty {
            return challengeManager.users.filter { $0.id != challengeManager.currentUser?.id }
        } else {
            return challengeManager.users.filter {
                $0.id != challengeManager.currentUser?.id &&
                ($0.username.lowercased().contains(searchText.lowercased()) ||
                 $0.email.lowercased().contains(searchText.lowercased()))
            }
        }
    }
    
    private var filteredChallenges: [Challenge] {
        if searchText.isEmpty {
            return challengeManager.challenges
        } else {
            return challengeManager.challenges.filter {
                $0.title.lowercased().contains(searchText.lowercased()) ||
                $0.description.lowercased().contains(searchText.lowercased())
            }
        }
    }
}
