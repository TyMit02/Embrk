
import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: AppSpacing.large) {
                    logoSection
                    
                    formSection
                    
                    signUpButton
                }
                .padding()
            }
            .navigationBarTitle("Sign Up", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var logoSection: some View {
        VStack {
            Image(systemName: "person.badge.plus")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(AppColors.primary)
            
            Text("Join Challenger")
                .font(AppFonts.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primary)
        }
    }
    
    private var formSection: some View {
        VStack(spacing: AppSpacing.medium) {
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
        .cornerRadius(15)
    }
    
    private var signUpButton: some View {
        Button(action: signUp) {
            Text("Sign Up")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary)
                .cornerRadius(10)
        }
    }
    
    private func signUp() {
           if password != confirmPassword {
               errorMessage = "Passwords do not match"
               showError = true
               return
           }
           
        let newUser = User(username: username, email: email, hashedPassword: hashPassword(password))
           if challengeManager.createUser(newUser) {
               challengeManager.login(user: newUser)
               isLoggedIn = true
               presentationMode.wrappedValue.dismiss()
           } else {
               errorMessage = "Username or email already exists"
               showError = true
           }
       }
}
