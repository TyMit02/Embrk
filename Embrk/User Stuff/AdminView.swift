//
//  AdminView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/10/24.
//


import SwiftUI

struct AdminView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        List {
            Section(header: Text("Data Management")) {
                Button("Reset All Challenge Data") {
                    resetAllChallengeData()
                }
                Button("Reset User Participations") {
                    resetUserParticipations()
                }
                
                Button("Reset Onboarding") {
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                }
            }
        }
        
        .navigationTitle("Admin Panel")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Admin Action"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func resetAllChallengeData() {
        challengeManager.resetAllChallengeData { result in
            switch result {
            case .success:
                alertMessage = "All challenge data has been reset successfully."
            case .failure(let error):
                alertMessage = "Failed to reset challenge data: \(error.localizedDescription)"
            }
            showAlert = true
        }
    }

    private func resetUserParticipations() {
        challengeManager.resetUserParticipations { result in
            switch result {
            case .success:
                alertMessage = "User participations have been reset successfully."
            case .failure(let error):
                alertMessage = "Failed to reset user participations: \(error.localizedDescription)"
            }
            showAlert = true
        }
    }
}
