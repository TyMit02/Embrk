import SwiftUI

struct LoginView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    //@StateObject private var authManager = AuthManager()
    @StateObject private var databaseManager = DatabaseManager()
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @Binding var isLoggedIn: Bool
    @State private var showSignUp = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: AppSpacing.large) {
                    logoSection
                    
                    formSection
                    
                    loginButton
                    
                    signUpButton
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView(isLoggedIn: $isLoggedIn)
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var logoSection: some View {
        VStack {
            Image(systemName: "figure.walk")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(AppColors.primary)
            
            Text("Challenger")
                .font(AppFonts.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primary)
        }
        .padding(.top, 50)
    }
    
    private var formSection: some View {
        VStack(spacing: AppSpacing.medium) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var loginButton: some View {
        Button(action: login) {
            Text("Login")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary)
                .cornerRadius(10)
        }
    }
    
    private var signUpButton: some View {
        Button(action: { showSignUp = true }) {
            Text("Don't have an account? Sign Up")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.primary)
        }
    }
    
    private func login() {
        if let user = challengeManager.authenticateUser(email: email, password: password) {
            challengeManager.login(user: user)
            isLoggedIn = true
        } else {
            errorMessage = "Invalid email or password"
            showError = true
        }
    }
    
    //    struct LoginView_Previews: PreviewProvider {
    //        static var previews: some View {
    //            Group {
    //                LoginView(isLoggedIn: $isLoggedIn)
    //                    .environmentObject(ChallengeManager())
    //                    .previewDisplayName("Light Mode")
    //
    //                LoginView()
    //                    .environmentObject(ChallengeManager())
    //                    .preferredColorScheme(.dark)
    //                    .previewDisplayName("Dark Mode")
    //            }
    //        }
    //    }
    //}
}
