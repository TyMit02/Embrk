import SwiftUI

struct DebugView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var showingConfirmation = false

    var body: some View {
        List {
            Section(header: Text("Danger Zone")) {
                Button("Reset All User Data") {
                    showingConfirmation = true
                }
                .foregroundColor(.red)
            }
            
            // Add more debug options here as needed
        }
        .navigationTitle("Debug Options")
        .alert("Confirm Reset", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                challengeManager.resetAllUserData()
            }
        } message: {
            Text("This will delete all user data. Are you sure?")
        }
    }
}
