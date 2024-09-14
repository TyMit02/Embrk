//
//  ChallengeDetailsView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//
import SwiftUI
import FirebaseFirestore

struct ChallengeDetailsView: View {
    @StateObject private var viewModel: ChallengeDetailsViewModel
    @EnvironmentObject var challengeManager: ChallengeManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showLeaderboard = false
    @State private var showingVerificationAlert = false
    @State private var verificationMessage = ""
    @State private var userProgress: Int = 0
    
    init(challenge: Challenge) {
        _viewModel = StateObject(wrappedValue: ChallengeDetailsViewModel(challenge: challenge))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                challengeHeader
                descriptionSection
                progressSection
                if viewModel.challenge.challengeType != .fitness {
                    userProgressUpdateSection
                }
                verificationSection
                participationSection
               // participantsSection
            }
            .padding()
            .padding(.bottom, 100)
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(viewModel.challenge.title, displayMode: .inline)
        //.navigationBarItems(trailing: leaderboardButton)
        .alert(isPresented: $showingVerificationAlert) {
            Alert(title: Text("Verification Result"), message: Text(verificationMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            viewModel.challengeManager = challengeManager
            viewModel.updateParticipationStatus()
        }
        .sheet(isPresented: $showLeaderboard) {LeaderboardView(leaderboardManager: LeaderboardManager(), challengeId: viewModel.challenge.id ?? "")
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var challengeHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(viewModel.challenge.title)
                .font(AppFonts.title2)
                .foregroundColor(AppColors.primary)
            
            HStack {
                Label(viewModel.challenge.difficulty, systemImage: "star.fill")
                    .font(AppFonts.footnote)
                    .foregroundColor(AppColors.yellow)
                
                Spacer()
                
                Label("\(viewModel.challenge.durationInDays) days", systemImage: "calendar")
                    .font(AppFonts.footnote)
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Description")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            Text(viewModel.challenge.description)
                .font(AppFonts.body)
                .foregroundColor(AppColors.text)
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var progressSection: some View {
           VStack(spacing: AppSpacing.small) {
               Text("Your Progress")
                   .font(AppFonts.headline)
                   .foregroundColor(AppColors.primary)
               
               let progress = Float(viewModel.challenge.userProgress[viewModel.challengeManager?.currentUser?.id ?? ""]?.count ?? 0)
               let total = Float(viewModel.challenge.durationInDays)
               
               ProgressView(value: progress, total: total)
                   .accentColor(AppColors.secondary)
               
               Text("\(Int(progress))/\(Int(total)) days completed")
                   .font(AppFonts.subheadline)
                   .foregroundColor(AppColors.text)
           }
           .padding()
           .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
           .cornerRadius(15)
       }
    
    private var userProgressUpdateSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("Update Today's Progress")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            TextField("Progress", value: $userProgress, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Update Progress") {
                Task {
                    await viewModel.updateUserProgress(progress: userProgress)
                }
            }
            .padding()
            .background(AppColors.primary)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var verificationSection: some View {
           VStack(spacing: AppSpacing.small) {
               Text("Daily Verification")
                   .font(AppFonts.headline)
                   .foregroundColor(AppColors.primary)
               
               Button(action: verifyChallenge) {
                   Text(viewModel.isVerifiedToday ? "Verified Today" : "Verify Today's Progress")
                       .font(AppFonts.headline)
                       .foregroundColor(.white)
                       .padding()
                       .frame(maxWidth: .infinity)
                       .background(viewModel.isVerifiedToday ? Color.gray : AppColors.secondary)
                       .cornerRadius(10)
               }
               .disabled(viewModel.isVerificationInProgress || viewModel.isVerifiedToday || !viewModel.canVerifyToday)
           }
           .padding()
           .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
           .cornerRadius(15)
       }
    
    private var participationSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("Participants: \(viewModel.challenge.participatingUsers.count)/\(viewModel.challenge.maxParticipants)")
                .font(AppFonts.body)
                .foregroundColor(AppColors.text)
            
            Button(action: {
                Task {
                    await viewModel.toggleParticipation()
                }
            }) {
                Text(viewModel.isParticipating ? "Leave Challenge" : "Join Challenge")
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isParticipating ? Color.red : AppColors.primary)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isRefreshing)
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Top Participants")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            ForEach(viewModel.challenge.participatingUsers.prefix(5), id: \.self) { userId in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(AppColors.primary)
                    Text(userId) // Replace with actual user names when available
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.text)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var leaderboardButton: some View {
        Button(action: { showLeaderboard = true }) {
            Image(systemName: "list.number")
                .foregroundColor(AppColors.primary)
        }
    }
    
    private func verifyChallenge() {
        Task {
            do {
                let success = try await viewModel.verifyChallenge()
                await MainActor.run {
                    verificationMessage = success ? "Verification successful!" : "Verification failed. Goal not met."
                    showingVerificationAlert = true
                }
            } catch {
                await MainActor.run {
                    verificationMessage = "Error: \(error.localizedDescription)"
                    showingVerificationAlert = true
                }
            }
        }
    }
}

class ChallengeDetailsViewModel: ObservableObject {
    @Published var challenge: Challenge
    @Published var isParticipating: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var isVerificationInProgress = false
    @Published var isVerifiedToday = false
    var challengeManager: ChallengeManager?
    private let verificationManager = VerificationManager()
    
    init(challenge: Challenge) {
        self.challenge = challenge
    }
    
    func updateParticipationStatus() {
        isParticipating = challengeManager?.isParticipating(in: challenge) ?? false
    }
    
    @MainActor
    func toggleParticipation() async {
        guard let challengeManager = challengeManager else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            if isParticipating {
                try await challengeManager.leaveChallenge(challenge.id ?? "")
            } else {
                try await challengeManager.joinChallenge(challenge.id ?? "")
            }
            await refreshChallenge()
        } catch {
            print("Error toggling participation: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func refreshChallenge() async {
        guard let challengeManager = challengeManager else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            if let challengeId = challenge.id {
                challenge = try await challengeManager.refreshChallenge(challengeId)
                updateParticipationStatus()
            }
        } catch {
            print("Error refreshing challenge: \(error.localizedDescription)")
        }
    }
    
    func verifyChallenge() async throws -> Bool {
            guard let user = challengeManager?.currentUser else {
                throw NSError(domain: "ChallengeDetailsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
            }
            
            isVerificationInProgress = true
            defer { isVerificationInProgress = false }
            
            let success = try await verificationManager.verifyChallenge(challenge, for: user)
            
            if success {
                await MainActor.run {
                    isVerifiedToday = true
                    updateProgress()
                }
            }
            
            return success
        }
        
    
    private func updateProgress() {
           if let userId = challengeManager?.currentUser?.id {
               challenge.userProgress[userId, default: []].append(Timestamp(date: Date()))
               challengeManager?.updateProgress(for: challenge.id ?? "", userId: userId, progress: challenge.userProgress[userId] ?? [])
           }
       }
    
    var canVerifyToday: Bool {
           guard let userId = challengeManager?.currentUser?.id else { return false }
           let today = Calendar.current.startOfDay(for: Date())
           return !(challenge.userProgress[userId]?.contains { Calendar.current.isDate($0.dateValue(), inSameDayAs: today) } ?? false)
       }
    
    @MainActor
    func updateUserProgress(progress: Int) async {
        guard let challengeId = challenge.id,
              let userId = challengeManager?.currentUser?.id else {
            print("Error: Missing challenge ID or user ID")
            return
        }
        
        do {
            try await challengeManager?.updateChallengeProgress(for: challengeId, userId: userId, progress: progress)
            print("Progress updated successfully")
            await refreshChallenge()
        } catch {
            print("Error updating progress: \(error.localizedDescription)")
        }
    }
}
