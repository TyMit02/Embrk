import SwiftUI

struct ChallengeDetailsView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showAlert = false
    @State private var alertMessage = ""
    let challenge: Challenge
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                headerSection
                detailsSection
                participantsSection
                if isParticipating {
                    progressSection
                }
                actionButton
            }
            .padding()
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Challenge Details", displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Challenge Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(challenge.title)
                .font(AppFonts.title1)
                .foregroundColor(AppColors.primary)
            
            if let creator = challengeManager.getUser(by: challenge.creatorId) {
                Text("Created by: \(creator.username)")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.lightText)
            } else if challenge.isOfficial {
                Text("Official Challenge")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBackground)
        .cornerRadius(15)
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(challenge.description)
                .font(AppFonts.body)
                .foregroundColor(AppColors.text)
            
            HStack {
                Label(challenge.difficulty, systemImage: "star.fill")
                    .foregroundColor(AppColors.yellow)
                Spacer()
                Label("Duration: \(challenge.durationInDays) days", systemImage: "calendar")
                    .foregroundColor(AppColors.primary)
            }
            .font(AppFonts.footnote)
            
            if let goal = challenge.verificationGoal {
                Text("Goal: \(formatGoal(goal))")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.secondary)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(15)
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Participants")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            Text("\(challenge.participatingUsers.count)/\(challenge.maxParticipants)")
                .font(AppFonts.body)
                .foregroundColor(AppColors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBackground)
        .cornerRadius(15)
    }
    
    @ViewBuilder
    private var progressSection: some View {
        if let progress = challengeManager.getUserProgressForChallenge(challenge.id ?? "") {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Your Progress")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                
                Text("\(progress)/\(challenge.durationInDays) days completed")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.primary)
                
                ProgressView(value: Double(progress), total: Double(challenge.durationInDays))
                    .accentColor(AppColors.primary)
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(15)
        }
    }
    
    private var actionButton: some View {
        Button(action: toggleParticipation) {
            Text(isParticipating ? "Leave Challenge" : "Join Challenge")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isParticipating ? Color.red : AppColors.primary)
                .cornerRadius(10)
        }
        .disabled(challenge.participatingUsers.count >= challenge.maxParticipants && !isParticipating)
    }
    
    private var isParticipating: Bool {
        challengeManager.isParticipating(in: challenge)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white
    }
    
    private func toggleParticipation() {
        if isParticipating {
            if challengeManager.leaveChallenge(challenge.id ?? "") {
                alertMessage = "You have left the challenge"
            } else {
                alertMessage = "Error leaving the challenge"
            }
        } else {
            if challengeManager.joinChallenge(challenge.id ?? "") {
                alertMessage = "You have joined the challenge"
            } else {
                alertMessage = "Error joining the challenge"
            }
        }
        showAlert = true
    }
    
    private func formatGoal(_ goal: Double) -> String {
        switch challenge.challengeType {
        case .fitness:
            switch challenge.healthKitMetric {
            case .steps:
                return "\(Int(goal)) steps"
            case .heartRate:
                return "\(Int(goal)) bpm"
            case .activeEnergy:
                return "\(Int(goal)) calories"
            case .distance:
                return String(format: "%.2f km", goal / 1000)
            case .workoutTime:
                return "\(Int(goal)) minutes"
            case .none:
                return "\(goal)"
            }
        case .education, .lifestyle, .miscellaneous:
            return "\(formatAmount(goal)) \(challenge.unitOfMeasurement ?? "units")"
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

struct ChallengeDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let challenge = Challenge(
            title: "30-Day Fitness Challenge",
            description: "Get fit with daily workouts and healthy habits",
            difficulty: "Medium",
            maxParticipants: 100,
            isOfficial: true,
            durationInDays: 30,
            creatorId: "official",
            challengeType: .fitness,
            healthKitMetric: .steps,
            verificationGoal: 10000
        )
        
        let challengeManager = ChallengeManager()
        
        return Group {
            NavigationView {
                ChallengeDetailsView(challenge: challenge)
                    .environmentObject(challengeManager)
            }
            .previewDisplayName("Light Mode")
            
            NavigationView {
                ChallengeDetailsView(challenge: challenge)
                    .environmentObject(challengeManager)
                    .preferredColorScheme(.dark)
            }
            .previewDisplayName("Dark Mode")
        }
    }
}