import SwiftUI

struct ChallengeDetailsView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @EnvironmentObject var educationVerificationManager: EducationVerificationManager
    @EnvironmentObject var lifestyleVerificationManager: LifestyleVerificationManager
    @EnvironmentObject var miscellaneousVerificationManager: MiscellaneousVerificationManager
    @ObservedObject var notificationStore: NotificationStore
    let challengeId: String
    @State private var challenge: Challenge
    @State private var isParticipating: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingVerificationSheet = false
    @State private var verificationAmount = ""
    @State private var verificationNotes = ""
    @State private var verificationEvidence: String = ""
    @Environment(\.colorScheme) var colorScheme

    init(challenge: Challenge, challengeManager: ChallengeManager) {
        self._challenge = State(initialValue: challenge)
        self.challengeId = challenge.id ?? ""
        self.notificationStore = challengeManager.notificationStore
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                detailsSection
                participantsSection
                if isParticipating {
                    progressSection
                }
                leaderboardSection
                challengeTimelineSection
                relatedChallengesSection
                actionButton
                
            }
            .padding()
            .padding(.bottom, 50)
        }
        .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("Challenge Details", displayMode: .inline)
        .onAppear(perform: updateChallengeState)
        .onChange(of: challengeManager.challenges) { _ in
            updateChallengeState()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Challenge Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showingVerificationSheet) {
            verificationSheet
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
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
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(challenge.description)
                .font(AppFonts.body)
                .foregroundColor(AppColors.lightText)

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
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }

    private var participantsSection: some View {
        Text("Current Participants: \(challenge.participatingUsers.count)/\(challenge.maxParticipants)")
            .font(AppFonts.subheadline)
            .foregroundColor(AppColors.lightText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
            .cornerRadius(15)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Progress")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.primary)

            if let progress = challengeManager.getUserProgressForChallenge(challenge.id ?? "") {
                Text("\(progress)/\(challenge.durationInDays) days completed")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.lightText)
            }

            Button(action: verifyAndMarkComplete) {
                Text("Verify and Mark Complete")
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(challengeManager.canMarkTodayAsCompleted(for: challenge.id ?? "") ? AppColors.primary : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!challengeManager.canMarkTodayAsCompleted(for: challenge.id ?? ""))

            if challenge.challengeType != .fitness {
                Button(action: { showingVerificationSheet = true }) {
                    Text("Log Progress")
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.secondary)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Leaderboard")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.primary)

            ForEach(getTopParticipants(), id: \.0) { participant in
                HStack {
                    Text(participant.0)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.lightText)
                    Spacer()
                    Text("\(participant.1) days")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.secondary)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }

    private var challengeTimelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Challenge Timeline")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.primary)

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Start Date")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.lightText)
                    Text(formatDate(Date())) // Replace with actual start date
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text("End Date")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.lightText)
                    Text(formatDate(Date().addingTimeInterval(TimeInterval(challenge.durationInDays * 24 * 60 * 60))))
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.primary)
                }
            }

            ProgressView(value: Double(challengeManager.getUserProgressForChallenge(challenge.id ?? "") ?? 0), total: Double(challenge.durationInDays))
                .accentColor(AppColors.primary)
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }

    private var relatedChallengesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Related Challenges")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(getRelatedChallenges(), id: \.id) { relatedChallenge in
                        NavigationLink(destination: ChallengeDetailsView(challenge: relatedChallenge, challengeManager: challengeManager)) {
                            VStack(alignment: .leading) {
                                Text(relatedChallenge.title)
                                    .font(AppFonts.headline)
                                    .foregroundColor(AppColors.primary)
                                    .lineLimit(2)
                                Text(relatedChallenge.difficulty)
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.secondary)
                            }
                            .frame(width: 150, height: 100)
                            .padding()
                            .background(colorScheme == .dark ? Color(hex: "2C2C2E") : Color.white)
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
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

    private var verificationSheet: some View {
        Group {
            switch challenge.challengeType {
            case .education:
                EducationVerificationSheet(challenge: challenge, verificationAmount: $verificationAmount, verificationNotes: $verificationNotes, onSubmit: submitEducationVerification)
            case .lifestyle:
                LifestyleVerificationSheet(challenge: challenge, verificationAmount: $verificationAmount, verificationNotes: $verificationNotes, onSubmit: submitLifestyleVerification)
            case .miscellaneous:
                MiscellaneousVerificationSheet(challenge: challenge, verificationEvidence: $verificationEvidence, onSubmit: submitMiscellaneousVerification)
            case .fitness:
                EmptyView()
            }
        }
    }

    private func verifyAndMarkComplete() {
        switch challenge.challengeType {
        case .fitness:
            HealthKitManager.shared.verifyChallenge(challenge) { goalReached, error in
                DispatchQueue.main.async {
                    handleVerificationResult(success: goalReached, error: error)
                }
            }
        case .education:
            if let userId = challengeManager.currentUser?.id,
               let dailyGoal = challenge.dailyGoal {
                let totalProgress = educationVerificationManager.getTotalProgress(for: challenge.id ?? "", userId: userId)
                handleVerificationResult(success: totalProgress >= dailyGoal, error: nil)
            }
        case .lifestyle:
            if let userId = challengeManager.currentUser?.id {
                lifestyleVerificationManager.verifyChallenge(challenge, userId: userId, amount: 0, notes: nil, evidenceImageURL: nil) { success, error in
                    DispatchQueue.main.async {
                        handleVerificationResult(success: success, error: error)
                    }
                }
            }
        case .miscellaneous:
            if let userId = challengeManager.currentUser?.id,
               let verificationMethod = challenge.miscVerificationMethod {
                miscellaneousVerificationManager.verifyChallenge(
                    challenge,
                    userId: userId,
                    method: verificationMethod,
                    evidence: nil
                ) { success, error in
                    DispatchQueue.main.async {
                        handleVerificationResult(success: success, error: error)
                    }
                }
            }
        }
    }

    private func handleVerificationResult(success: Bool, error: Error?) {
        if let error = error {
            alertMessage = "Error verifying challenge: \(error.localizedDescription)"
        } else if success {
            challengeManager.markDayAsCompleted(for: challenge.id ?? "")
            alertMessage = "Challenge verified and marked as complete for today!"
            notificationStore.addNotification(title: "Challenge Complete", message: "You've completed today's goal for \(challenge.title)")
        } else {
            alertMessage = "Challenge goal not yet reached. Keep going!"
        }
        showAlert = true
    }

    private func submitEducationVerification() {
        guard let amount = Int(verificationAmount), let userId = challengeManager.currentUser?.id else { return }
        
        educationVerificationManager.addVerification(
            for: challenge,
            userId: userId,
            amount: amount,
            notes: verificationNotes,
            evidenceImageURL: nil
        )
        
        showingVerificationSheet = false
        verificationAmount = ""
        verificationNotes = ""
        
        if let dailyGoal = challenge.dailyGoal,
           educationVerificationManager.getTotalProgress(for: challenge.id ?? "", userId: userId) >= dailyGoal {
            challengeManager.markDayAsCompleted(for: challenge.id ?? "")
            notificationStore.addNotification(title: "Daily Goal Achieved", message: "You've met your daily goal for \(challenge.title)!")
        }
    }

    private func submitLifestyleVerification() {
        guard let amount = Double(verificationAmount), let userId = challengeManager.currentUser?.id else { return }
        
        lifestyleVerificationManager.verifyChallenge(challenge, userId: userId, amount: amount, notes: verificationNotes, evidenceImageURL: nil) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Error verifying challenge: \(error.localizedDescription)"
                } else if success {
                    alertMessage = "Progress logged successfully!"
                    challengeManager.markDayAsCompleted(for: challenge.id ?? "")
                    notificationStore.addNotification(title: "Challenge Progress", message: "You've logged progress for \(challenge.title)")
                } else {
                    alertMessage = "Progress logged, but daily goal not yet reached. Keep going!"
                }
                showAlert = true
                showingVerificationSheet = false
                verificationAmount = ""
                verificationNotes = ""
            }
        }
    }

    private func submitMiscellaneousVerification() {
        guard let userId = challengeManager.currentUser?.id,
              let verificationMethod = challenge.miscVerificationMethod else { return }
        
        miscellaneousVerificationManager.verifyChallenge(
            challenge,
            userId: userId,
                       method: verificationMethod,
                       evidence: verificationEvidence
                   ) { success, error in
                       DispatchQueue.main.async {
                           if let error = error {
                               alertMessage = "Error verifying challenge: \(error.localizedDescription)"
                           } else if success {
                               alertMessage = "Verification submitted successfully!"
                               challengeManager.markDayAsCompleted(for: challenge.id ?? "")
                               notificationStore.addNotification(title: "Challenge Progress", message: "You've submitted a verification for \(challenge.title)")
                           } else {
                               alertMessage = "Verification not successful. Please try again."
                           }
                           showAlert = true
                           showingVerificationSheet = false
                           verificationEvidence = ""
                       }
                   }
               }

               private func toggleParticipation() {
                   if isParticipating {
                       if challengeManager.leaveChallenge(challengeId) {
                           isParticipating = false
                           alertMessage = "You have left the challenge"
                       } else {
                           alertMessage = "Error leaving the challenge"
                       }
                   } else {
                       if challengeManager.joinChallenge(challengeId ) {
                           isParticipating = true
                           alertMessage = "You have joined the challenge"
                       } else {
                           alertMessage = "Error joining the challenge"
                       }
                   }
                   showAlert = true
                   updateChallengeState()
               }

               private func updateChallengeState() {
                   if let updatedChallenge = challengeManager.challenges.first(where: { $0.id == challengeId }) {
                       challenge = updatedChallenge
                       isParticipating = challengeManager.isParticipating(in: updatedChallenge)
                   }
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

               private func getTopParticipants() -> [(String, Int)] {
                   // This is a placeholder. Implement actual leaderboard logic here.
                   return [("User1", 15), ("User2", 12), ("User3", 10)]
               }

               private func formatDate(_ date: Date) -> String {
                   let formatter = DateFormatter()
                   formatter.dateStyle = .medium
                   return formatter.string(from: date)
               }

               private func getRelatedChallenges() -> [Challenge] {
                   // This is a placeholder. Implement actual related challenges logic here.
                   return challengeManager.challenges.filter { $0.challengeType == challenge.challengeType && $0.id != challenge.id }.prefix(5).map { $0 }
               }
           }

           struct EducationVerificationSheet: View {
               let challenge: Challenge
               @Binding var verificationAmount: String
               @Binding var verificationNotes: String
               let onSubmit: () -> Void
               @Environment(\.colorScheme) var colorScheme

               var body: some View {
                   NavigationView {
                       Form {
                           Section(header: Text("Log Progress").font(AppFonts.headline)) {
                               TextField("Amount", text: $verificationAmount)
                                   .keyboardType(.numberPad)
                               TextField("Notes (optional)", text: $verificationNotes)
                           }
                           
                           Button(action: onSubmit) {
                               Text("Submit")
                                   .font(AppFonts.headline)
                                   .foregroundColor(.white)
                                   .frame(maxWidth: .infinity)
                                   .padding()
                                   .background(AppColors.primary)
                                   .cornerRadius(10)
                           }
                           .listRowBackground(Color.clear)
                       }
                       .navigationBarTitle("Log Progress", displayMode: .inline)
                   }
                   .accentColor(AppColors.primary)
               }
           }

           struct LifestyleVerificationSheet: View {
               let challenge: Challenge
               @Binding var verificationAmount: String
               @Binding var verificationNotes: String
               let onSubmit: () -> Void
               @Environment(\.colorScheme) var colorScheme

               var body: some View {
                   NavigationView {
                       Form {
                           Section(header: Text("Log Progress").font(AppFonts.headline)) {
                               TextField("Amount", text: $verificationAmount)
                                   .keyboardType(.decimalPad)
                               TextField("Notes (optional)", text: $verificationNotes)
                           }
                           
                           Button(action: onSubmit) {
                               Text("Submit")
                                   .font(AppFonts.headline)
                                   .foregroundColor(.white)
                                   .frame(maxWidth: .infinity)
                                   .padding()
                                   .background(AppColors.primary)
                                   .cornerRadius(10)
                           }
                           .listRowBackground(Color.clear)
                       }
                       .navigationBarTitle("Log Progress", displayMode: .inline)
                   }
                   .accentColor(AppColors.primary)
               }
           }

           struct MiscellaneousVerificationSheet: View {
               let challenge: Challenge
               @Binding var verificationEvidence: String
               let onSubmit: () -> Void
               @Environment(\.colorScheme) var colorScheme

               var body: some View {
                   NavigationView {
                       Form {
                           Section(header: Text("Submit Verification").font(AppFonts.headline)) {
                               switch challenge.miscVerificationMethod {
                               case .photo:
                                   Text("Photo upload not implemented in this example")
                                       .font(AppFonts.body)
                                       .foregroundColor(AppColors.lightText)
                               case .textInput:
                                   TextField("Enter your verification text", text: $verificationEvidence)
                               case .checkbox:
                                   Toggle("I completed this task", isOn: Binding(
                                       get: { !verificationEvidence.isEmpty },
                                       set: { verificationEvidence = $0 ? "checked" : "" }
                                   ))
                               case .numericInput:
                                   TextField("Enter a number", text: $verificationEvidence)
                                       .keyboardType(.numberPad)
                               case .locationCheck:
                                   Text("Enter latitude,longitude")
                                       .font(AppFonts.caption)
                                       .foregroundColor(AppColors.lightText)
                                   TextField("e.g. 40.7128,-74.0060", text: $verificationEvidence)
                                       .keyboardType(.decimalPad)
                               case .timerBased:
                                   Text("Timer-based verification not implemented in this example")
                                       .font(AppFonts.body)
                                       .foregroundColor(AppColors.lightText)
                               case .socialMediaPost:
                                   TextField("Enter link to your social media post", text: $verificationEvidence)
                               case .fileUpload:
                                   Text("File upload not implemented in this example")
                                       .font(AppFonts.body)
                                       .foregroundColor(AppColors.lightText)
                               case .none:
                                   Text("No verification method specified")
                                       .font(AppFonts.body)
                                       .foregroundColor(AppColors.lightText)
                               }
                           }
                           
                           Button(action: onSubmit) {
                               Text("Submit")
                                   .font(AppFonts.headline)
                                   .foregroundColor(.white)
                                   .frame(maxWidth: .infinity)
                                   .padding()
                                   .background(AppColors.primary)
                                   .cornerRadius(10)
                           }
                           .listRowBackground(Color.clear)
                       }
                       .navigationBarTitle("Verify Challenge", displayMode: .inline)
                   }
                   .accentColor(AppColors.primary)
               }
           }

           struct ChallengeDetailsView_Previews: PreviewProvider {
               static var previews: some View {
                   let sampleChallenge = Challenge(
                       title: "30-Day Fitness",
                       description: "Complete daily workouts for 30 days",
                       difficulty: "Medium",
                       maxParticipants: 1000,
                       isOfficial: true,
                       durationInDays: 30,
                       creatorId: "creator",
                       challengeType: .fitness,
                       healthKitMetric: .steps,
                       verificationGoal: 10000
                   )
                   
                   let challengeManager = ChallengeManager()
                   
                   return Group {
                       NavigationView {
                           ChallengeDetailsView(challenge: sampleChallenge, challengeManager: challengeManager)
                       }
                       .environmentObject(challengeManager)
                       .environmentObject(EducationVerificationManager())
                       .environmentObject(LifestyleVerificationManager())
                       .environmentObject(MiscellaneousVerificationManager())
                       .previewDisplayName("Light Mode")

                       NavigationView {
                           ChallengeDetailsView(challenge: sampleChallenge, challengeManager: challengeManager)
                       }
                       .environmentObject(challengeManager)
                       .environmentObject(EducationVerificationManager())
                       .environmentObject(LifestyleVerificationManager())
                       .environmentObject(MiscellaneousVerificationManager())
                       .preferredColorScheme(.dark)
                       .previewDisplayName("Dark Mode")
                   }
               }
           }
