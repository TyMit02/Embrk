//
//  ChallengeDetailsView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//

import SwiftUI
import FirebaseCore

struct ChallengeDetailsView: View {
    @StateObject private var viewModel: ChallengeDetailsViewModel
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showLeaderboard = false
    @State private var showingVerificationAlert = false
    @State private var showingDetailedVerification = false
    @State private var completionLevel: CompletionLevel = .all
    @State private var verificationMessage = ""
    
    init(challenge: Challenge) {
        _viewModel = StateObject(wrappedValue: ChallengeDetailsViewModel(challenge: challenge))
    }
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    headerSection
                    participationSection
                    descriptionSection
                    progressSection
                    validationSection
                    participantsSection
                }
                .padding()
            }
            .padding(.bottom, 100)
        }
        .navigationTitle(viewModel.challenge.title)
        .navigationBarItems(trailing: leaderboardButton)
        .refreshable {
            await viewModel.refreshChallenge()
        }
        .onAppear {
            viewModel.challengeManager = challengeManager
            viewModel.updateParticipationStatus()
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView(leaderboardManager: LeaderboardManager(), challengeId: viewModel.challenge.id ?? "")
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: challengeTypeIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
                .foregroundColor(AppColors.primary)
            
            Text(viewModel.challenge.title)
                .font(AppFonts.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.text)
            
            Text("Created by: \(viewModel.challenge.creatorId)")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var participationSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("Participants: \(viewModel.challenge.participatingUsers.count)/\(viewModel.challenge.maxParticipants)")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            Button(viewModel.isParticipating ? "Leave Challenge" : "Join Challenge") {
                Task {
                    await viewModel.toggleParticipation()
                }
            }
            .font(AppFonts.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(viewModel.isParticipating ? Color.red : AppColors.primary)
            .cornerRadius(10)
            .disabled(viewModel.isRefreshing)
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private var validationSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("Daily Verification")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            Button(action: {
                Task {
                    await verifyChallenge()
                }
            }) {
                Text(viewModel.isVerifiedToday ? "Verified Today" : "Verify Today's Progress")
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isVerifiedToday ? Color.gray : AppColors.secondary)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isVerificationInProgress || viewModel.isVerifiedToday || !viewModel.canVerifyToday)
            .alert("Verification Result", isPresented: $showingVerificationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(verificationMessage)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
       
   
    private func verifyChallenge() async {
        do {
            let success = try await viewModel.verifyChallenge()
            await MainActor.run {
                verificationMessage = success ? "Verification successful!" : "Verification failed. Goal not met."
                showingVerificationAlert = true
            }
        } catch {
            await MainActor.run {
                if let nsError = error as NSError? {
                    verificationMessage = "Error: \(nsError.localizedDescription)"
                    print("DEBUG: Detailed error: \(nsError)")
                } else {
                    verificationMessage = "An unknown error occurred"
                }
                showingVerificationAlert = true
            }
        }
    }
    
    private var canVerifyToday: Bool {
        viewModel.canVerifyToday
    }
    
 
  
    private var shouldShowDetailedVerification: Bool {
           // Logic to determine if we should show detailed verification
           // Could be random, based on progress, etc.
           return Int.random(in: 1...5) == 1
       }
   
    
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Top Participants")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            ForEach(viewModel.challenge.participatingUsers.prefix(5), id: \.self) { userId in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(AppColors.lightText)
                    Text(userId) // Replace with actual user names when available
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.text)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var leaderboardButton: some View {
        Button(action: { showLeaderboard = true }) {
            Image(systemName: "chart.bar.fill")
                .foregroundColor(AppColors.primary)
        }
    }
    
    private var challengeTypeIcon: String {
        switch viewModel.challenge.challengeType {
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
enum CompletionLevel: String, CaseIterable, Identifiable {
    case all, most, some, attempted

    var id: String { self.rawValue }

    var description: String {
        switch self {
        case .all: return "All of it"
        case .most: return "Most of it"
        case .some: return "Some of it"
        case .attempted: return "None, but I tried"
        }
    }
}
class ChallengeDetailsViewModel: ObservableObject {
    @Published var challenge: Challenge
    @Published var isParticipating: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String?
    @Published var isVerifying = false
    @Published var isVerificationInProgress = false
    @Published var isVerifiedToday = false
    var challengeManager: ChallengeManager?

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
            errorMessage = "Error: \(error.localizedDescription)"
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
            errorMessage = "Error refreshing challenge: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func validateTodaysProgress() async {
        guard let challengeManager = challengeManager, let challengeId = challenge.id else { return }
        
        do {
            try await challengeManager.markDayAsCompleted(for: challengeId)
            await refreshChallenge()
        } catch {
            errorMessage = "Error validating progress: \(error.localizedDescription)"
        }
    }
    
    var canVerifyToday: Bool {
        guard let lastVerification = challenge.userProgress[challengeManager?.currentUser?.id ?? ""]?.last else {
            return true
        }
        return !Calendar.current.isDateInToday(lastVerification.dateValue())
    }
    
    func verifyChallenge() async throws -> Bool {
        guard let challengeManager = challengeManager else {
            throw NSError(domain: "com.yourapp.challenge", code: 0, userInfo: [NSLocalizedDescriptionKey: "ChallengeManager not available"])
        }
        
        isVerificationInProgress = true
        defer { isVerificationInProgress = false }
        
        do {
            let success: Bool
            switch challenge.challengeType {
            case .fitness:
                success = try await verifyFitnessChallenge(challenge)
            case .education, .lifestyle, .miscellaneous:
                success = try await verifyNonFitnessChallenge(challenge)
            }
            
            if success {
                await MainActor.run {
                    isVerifiedToday = true
                    updateProgress()
                }
            }
            
            return success
        } catch {
            print("Verification error: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("DEBUG: Detailed error: \(nsError)")
            }
            throw error
        }
    }
    
    private func updateProgress() {
        if let userId = challengeManager?.currentUser?.id {
            challenge.userProgress[userId, default: []].append(Timestamp(date: Date()))
        }
    }
    private func verifyFitnessChallenge(_ challenge: Challenge) async throws -> Bool {
        print("DEBUG: Verifying fitness challenge - Type: \(challenge.challengeType), HealthKit Metric: \(String(describing: challenge.healthKitMetric)), Verification Goal: \(String(describing: challenge.verificationGoal))")
        
        guard let healthKitMetric = challenge.healthKitMetric else {
            print("DEBUG: HealthKit metric is nil")
            throw NSError(domain: "com.yourapp.challenge", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid fitness challenge configuration: HealthKit metric is missing"])
        }
        
        guard let goal = challenge.verificationGoal else {
            print("DEBUG: Verification goal is nil")
            throw NSError(domain: "com.yourapp.challenge", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid fitness challenge configuration: Verification goal is missing"])
        }
        
        do {
            try await HealthKitManager.shared.requestAuthorization()
        } catch {
            print("DEBUG: HealthKit authorization failed: \(error.localizedDescription)")
            throw NSError(domain: "com.yourapp.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit authorization failed: \(error.localizedDescription)"])
        }
        
        switch healthKitMetric {
        case .steps:
            let steps = try await HealthKitManager.shared.getStepCountAsync(for: Date())
            print("DEBUG: Steps: \(steps), Goal: \(goal)")
            return steps >= goal
            
        case .activeEnergy:
            let calories = try await HealthKitManager.shared.getActiveEnergyBurnedAsync(for: Date())
            print("DEBUG: Calories: \(calories), Goal: \(goal)")
            return calories >= goal
            
        default:
            print("DEBUG: Unsupported HealthKit metric: \(healthKitMetric)")
            throw NSError(domain: "com.yourapp.challenge", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported HealthKit metric"])
        }
    }
    
    private func verifyNonFitnessChallenge(_ challenge: Challenge) async throws -> Bool {
        // For now, we'll trust the user's input for non-fitness challenges
        // In the future, you might implement more sophisticated verification methods
        return true
    }
}

//struct ChallengeDetailsView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            ChallengeDetailsView(challenge: Challenge(
//                title: "30-Day Fitness Challenge",
//                description: "Get fit with daily workouts!",
//                difficulty: "Medium",
//                maxParticipants: 100,
//                isOfficial: true,
//                durationInDays: 30,
//                creatorId: "official",
//                challengeType: .fitness
//            ))
//            .environmentObject(ChallengeManager())
//        }
//    }
//}
