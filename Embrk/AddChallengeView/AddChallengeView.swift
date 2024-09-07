
import SwiftUI

struct AddChallengeView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var title = ""
    @State private var description = ""
    @State private var difficulty = "Easy"
    @State private var maxParticipants = 10
    @State private var durationInDays = 30
    @State private var selectedType: ChallengeType = .fitness
    @State private var selectedHealthKitMetric: HealthKitMetric?
    @State private var selectedVerificationMethod: Challenge.VerificationMethod = .manual
    @State private var selectedMiscVerificationMethod: MiscellaneousVerificationManager.VerificationMethod = .checkbox
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var verificationGoal: String = ""
    @State private var selectedEducationType: Challenge.EducationType = .reading
    @State private var selectedLifestyleType: Challenge.LifestyleType = .meditation
    @State private var unitOfMeasurement: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                basicInfoSection
                challengeTypeSection
                specificDetailsSection
                saveButton
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("Create Challenge", displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Challenge Creation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private var headerSection: some View {
        Text("Create a New Challenge")
            .font(AppFonts.title1)
            .foregroundColor(AppColors.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            TextField("Challenge Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Description", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Picker("Difficulty", selection: $difficulty) {
                ForEach(["Easy", "Medium", "Hard"], id: \.self) { Text($0) }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            HStack {
                Text("Max Participants: \(maxParticipants)")
                Spacer()
                Stepper("", value: $maxParticipants, in: 1...1000)
            }
            
            HStack {
                Text("Duration: \(durationInDays) days")
                Spacer()
                Stepper("", value: $durationInDays, in: 1...365)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var challengeTypeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Challenge Type")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            Picker("Challenge Type", selection: $selectedType) {
                ForEach(ChallengeType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var specificDetailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Specific Details")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            switch selectedType {
            case .fitness:
                fitnessDetails
            case .education:
                educationDetails
            case .lifestyle:
                lifestyleDetails
            case .miscellaneous:
                miscellaneousDetails
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var fitnessDetails: some View {
        Picker("HealthKit Metric", selection: $selectedHealthKitMetric) {
            Text("None").tag(nil as HealthKitMetric?)
            ForEach(HealthKitMetric.allCases, id: \.self) { metric in
                Text(metric.rawValue).tag(metric as HealthKitMetric?)
            }
        }
    }
    
    private var educationDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Education Type", selection: $selectedEducationType) {
                ForEach(Challenge.EducationType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            TextField("Unit of Measurement", text: $unitOfMeasurement)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Daily Goal", text: $verificationGoal)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
        }
    }
    
    private var lifestyleDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Lifestyle Type", selection: $selectedLifestyleType) {
                ForEach(Challenge.LifestyleType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            Picker("Verification Method", selection: $selectedVerificationMethod) {
                ForEach(Challenge.VerificationMethod.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            if selectedVerificationMethod == .manual {
                TextField("Verification Goal", text: $verificationGoal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
            }
        }
    }
    
    private var miscellaneousDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Verification Method", selection: $selectedMiscVerificationMethod) {
                ForEach(MiscellaneousVerificationManager.VerificationMethod.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            if selectedMiscVerificationMethod == .numericInput || selectedMiscVerificationMethod == .timerBased {
                TextField("Verification Goal", text: $verificationGoal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: saveChallenge) {
            Text("Create Challenge")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary)
                .cornerRadius(15)
        }
    }
    
    private func saveChallenge() {
        guard !title.isEmpty && !description.isEmpty else {
            alertMessage = "Please fill in all fields"
            showAlert = true
            return
        }
        
        guard let currentUser = challengeManager.currentUser else {
            alertMessage = "Error: User not logged in"
            showAlert = true
            return
        }
        
        let newChallenge = Challenge(
            title: title,
            description: description,
            difficulty: difficulty,
            maxParticipants: maxParticipants,
            isOfficial: false,
            durationInDays: durationInDays,
            creatorId: currentUser.id ?? "",
            challengeType: selectedType,
            healthKitMetric: selectedHealthKitMetric,
            verificationGoal: Double(verificationGoal),
            educationType: selectedType == .education ? selectedEducationType : nil,
            unitOfMeasurement: selectedType == .education ? unitOfMeasurement : nil,
            dailyGoal: selectedType == .education ? Int(verificationGoal) : nil,
            lifestyleType: selectedType == .lifestyle ? selectedLifestyleType : nil,
            verificationMethod: selectedType == .lifestyle ? selectedVerificationMethod : .manual
        )


        challengeManager.addChallenge(newChallenge)
        challengeManager.addCreatedChallenge(newChallenge, for: currentUser)
        
        alertMessage = "Challenge created successfully!"
        showAlert = true
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddChallengeView()
                .environmentObject(ChallengeManager())
        }
    }
}
