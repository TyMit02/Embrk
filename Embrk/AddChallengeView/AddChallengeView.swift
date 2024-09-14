//
//  AddChallengeView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/8/24.
//

import SwiftUI
import FirebaseFirestore

struct AddChallengeView: View {
    @StateObject private var viewModel = AddChallengeViewModel()
    @EnvironmentObject var challengeManager: ChallengeManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: AppSpacing.large) {
                        basicInfoSection
                        challengeTypeSection
                        
                        switch viewModel.selectedType {
                        case .fitness:
                            fitnessSection
                        case .education:
                            educationSection
                        case .lifestyle:
                            lifestyleSection
                        case .miscellaneous:
                            miscellaneousSection
                        }
                        
                        if authManager.currentUser?.isAdmin == true {
                            officialToggleSection
                        }
                        
                        createButton
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitle("Create Challenge", displayMode: .inline)
            .navigationBarItems(leading: cancelButton)
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Challenge Creation"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            sectionHeader("Basic Information")
            
            customTextField(title: "Challenge Title", text: $viewModel.title)
            
            customTextEditor(title: "Description", text: $viewModel.description)
            
            customPicker(title: "Difficulty", selection: $viewModel.difficulty, options: ["Easy", "Medium", "Hard"])
            
            customStepper(title: "Max Participants", value: $viewModel.maxParticipants, range: 1...1000)
            
            customDatePicker(title: "Start Date", selection: $viewModel.startDate)
            
            customStepper(title: "Duration (days)", value: $viewModel.durationInDays, range: 1...365)
        }
        .padding()
        .background(sectionBackground)
        .cornerRadius(15)
    }
    
    private var challengeTypeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            sectionHeader("Challenge Type")
            
            Picker("Challenge Type", selection: $viewModel.selectedType) {
                ForEach(ChallengeType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(sectionBackground)
        .cornerRadius(15)
    }
    
    private var fitnessSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            sectionHeader("Fitness Details")
            
            CustomDropdownMenu(
                title: "Metric",
                selection: $viewModel.selectedHealthKitMetric,
                options: HealthKitMetric.allCases
            )
            
            customTextField(title: "Daily Goal", text: $viewModel.verificationGoal, keyboardType: .numberPad)
        }
        .padding()
        .background(sectionBackground)
        .cornerRadius(15)
    }
    
    private var lifestyleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            sectionHeader("Lifestyle Details")
            
            CustomDropdownMenu(
                title: "Lifestyle Type",
                selection: $viewModel.selectedLifestyleType,
                options: Challenge.LifestyleType.allCases
            )
            
            customTextField(title: "Daily Goal", text: $viewModel.verificationGoal, keyboardType: .numberPad)
            customTextField(title: "Unit of Measurement", text: $viewModel.unitOfMeasurement)
        }
        .padding()
        .background(sectionBackground)
        .cornerRadius(15)
    }

    private var educationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            sectionHeader("Education Details")
            
            CustomDropdownMenu(
                title: "Education Type",
                selection: $viewModel.selectedEducationType,
                options: Challenge.EducationType.allCases
            )
            
            customTextField(title: "Daily Goal", text: $viewModel.verificationGoal, keyboardType: .numberPad)
            customTextField(title: "Unit of Measurement", text: $viewModel.unitOfMeasurement)
        }
        .padding()
        .background(sectionBackground)
        .cornerRadius(15)
    }

    private var miscellaneousSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            sectionHeader("Miscellaneous Details")
            
            CustomDropdownMenu(
                title: "Verification Method",
                selection: $viewModel.selectedVerificationMethod,
                options: Challenge.VerificationMethod.allCases
            )
            
            if viewModel.selectedVerificationMethod == .timeBased {
                customTextField(title: "Daily Goal (minutes)", text: $viewModel.verificationGoal, keyboardType: .numberPad)
            }
        }
        .padding()
        .background(sectionBackground)
        .cornerRadius(15)
    }
    
    private var officialToggleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            sectionHeader("Official Status")
            Toggle("Official Challenge", isOn: $viewModel.isOfficial)
        }
        .padding()
        .background(sectionBackground)
        .cornerRadius(15)
    }
    
    private var cancelButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(AppColors.primary)
        }
    }
    
    private var createButton: some View {
        Button(action: {
            viewModel.createChallenge(challengeManager: challengeManager, authManager: authManager) { result in
                switch result {
                case .success:
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    viewModel.showAlert = true
                    viewModel.alertMessage = error.localizedDescription
                }
            }
        }) {
            Text("Create Challenge")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary)
                .cornerRadius(10)
        }
    }
    
    // Helper Views
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppFonts.headline)
            .foregroundColor(AppColors.primary)
    }
    
    private func customTextField(title: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
            TextField(title, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
        }
    }
    
    private func customTextEditor(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
            TextEditor(text: text)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
        }
    }
    
    struct CustomDropdownMenu<T: Hashable & CustomStringConvertible>: View {
        let title: String
        let selection: Binding<T?>
        let options: [T]
        
        @State private var isExpanded = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.lightText)
                
                DisclosureGroup(
                    isExpanded: $isExpanded,
                    content: {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(options, id: \.self) { option in
                                    Text(option.description)
                                        .font(AppFonts.body)
                                        .padding(.vertical, 5)
                                        .onTapGesture {
                                            selection.wrappedValue = option
                                            withAnimation {
                                                self.isExpanded.toggle()
                                            }
                                        }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    },
                    label: {
                        Text(selection.wrappedValue?.description ?? "Select \(title)")
                            .foregroundColor(selection.wrappedValue == nil ? AppColors.lightText : AppColors.text)
                            .font(AppFonts.body)
                    }
                )
                .accentColor(AppColors.primary)
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.lightText, lineWidth: 1)
                )
            }
        }
    }
    
    private func customPicker<T: Hashable & CustomStringConvertible>(
        title: String,
        selection: Binding<T>,
        options: [T]
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.description).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    // Overload for optional bindings
    private func customPicker<T: Hashable & CustomStringConvertible>(
        title: String,
        selection: Binding<T?>,
        options: [T]
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
            Picker(title, selection: selection) {
                Text("Select \(title)").tag(nil as T?)
                ForEach(options, id: \.self) { option in
                    Text(option.description).tag(option as T?)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private func customStepper(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(title)
                .font(AppFonts.body)
                .foregroundColor(AppColors.text)
            Spacer()
            Stepper("\(value.wrappedValue)", value: value, in: range)
        }
    }
    
    private func customDatePicker(title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
            DatePicker("", selection: selection, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
        }
    }
    
    private var sectionBackground: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white
    }
}

class AddChallengeViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var difficulty = "Easy"
    @Published var maxParticipants = 10
    @Published var startDate = Date()
    @Published var durationInDays = 30
    @Published var selectedType: ChallengeType = .fitness
    @Published var selectedHealthKitMetric: HealthKitMetric?
    @Published var selectedEducationType: Challenge.EducationType?
    @Published var selectedLifestyleType: Challenge.LifestyleType?
    @Published var selectedVerificationMethod: Challenge.VerificationMethod?
    @Published var verificationGoal = ""
    @Published var unitOfMeasurement = ""
    @Published var isOfficial = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    func createChallenge(challengeManager: ChallengeManager, authManager: AuthManager, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = authManager.currentUser else {
            completion(.failure(NSError(domain: "AddChallengeViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        let newChallenge = Challenge(
            title: title,
            description: description,
            difficulty: difficulty,
            maxParticipants: maxParticipants,
            isOfficial: isOfficial,
            durationInDays: durationInDays,
            creatorId: currentUser.id ?? "",
            challengeType: selectedType,
            healthKitMetric: selectedType == .fitness ? selectedHealthKitMetric : nil,
            verificationGoal: selectedType == .fitness ? Double(verificationGoal) : nil,
            educationType: selectedType == .education ? selectedEducationType : nil,
            unitOfMeasurement: selectedType == .education || selectedType == .lifestyle ? unitOfMeasurement : nil,
            dailyGoal: selectedType == .education || selectedType == .lifestyle ? Int(verificationGoal) : nil,
            lifestyleType: selectedType == .lifestyle ? selectedLifestyleType : nil,
            verificationMethod: (selectedType == .miscellaneous ? selectedVerificationMethod : .manual)!,
            startDate: startDate
        )
        
        challengeManager.addChallenge(newChallenge)
        completion(.success(()))
    }
}

struct AddChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        AddChallengeView()
            .environmentObject(ChallengeManager(authManager: AuthManager(), firestoreService: FirestoreService()))
            .environmentObject(AuthManager())
    }
}
