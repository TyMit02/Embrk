//
//  LoginView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/8/24.
//


import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @Binding var isLoggedIn: Bool
    @State private var showSignUp = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
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
            
            Text("Embrk")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primary)
        }
        .padding(.top, 50)
    }
    
    private var formSection: some View {
        VStack(spacing: 15) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(colorScheme == .dark ? Color(white: 0.1) : Color.white)
        .cornerRadius(15)
    }
    
    private var loginButton: some View {
        Button(action: login) {
            Text("Login")
                .font(.headline)
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
                .font(.subheadline)
                .foregroundColor(AppColors.primary)
        }
    }
    
    private func login() {
           guard isValidForm() else { return }
           
           authManager.signIn(email: email, password: password) { result in
               switch result {
               case .success(let user):
                   print("Successfully signed in: \(user.username)")
               case .failure(let error):
                   print("Sign in error: \(error.localizedDescription)")
                   errorMessage = error.localizedDescription
                   showError = true
               }
           }
       }
       
       private func isValidForm() -> Bool {
           if email.isEmpty || password.isEmpty {
               errorMessage = "Please fill in all fields"
               showError = true
               return false
           }
           if !email.contains("@") {
               errorMessage = "Please enter a valid email address"
               showError = true
               return false
           }
           return true
       }
}
