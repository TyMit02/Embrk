//
//  SideMenuView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//


import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedTab: Int
    @State private var selectedOption: SideMenuOptionModel?
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var showLoginView = false
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SideMenuHeaderView()
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(SideMenuOptionModel.allCases) { option in
                        Button(action: {
                            onOptionTapped(option)
                        }) {
                            SideMenuRowView(option: option, selectedOption: $selectedOption)
                        }
                    }
                }
            }
            
            Spacer()
            
            authenticationButton
        }
        .padding(.top, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(backgroundColor)
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showLoginView) {
            LoginView(isLoggedIn: $authManager.isLoggedIn)
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white
    }
    
    private var authenticationButton: some View {
        Group {
            if authManager.isLoggedIn {
                Button(action: {
                    authManager.signOut { result in
                        switch result {
                        case .success:
                            isShowing = false
                        case .failure(let error):
                            print("Error signing out: \(error.localizedDescription)")
                            // Handle the error appropriately
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.left.square")
                        Text("Logout")
                    }
                    .font(AppFonts.headline)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
            } else {
                Button(action: {
                    showLoginView = true
                    isShowing = false
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Login")
                    }
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }

    private func onOptionTapped(_ option: SideMenuOptionModel) {
        selectedOption = option
        selectedTab = option.rawValue
        withAnimation(.easeInOut) {
            isShowing = false
        }
    }
}

struct SideMenuHeaderView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(AppColors.primary)
            
            Text(authManager.currentUser?.username ?? "Guest")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.text)
            
            Text(authManager.currentUser?.email ?? "Not logged in")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7"))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct SideMenuRowView: View {
    let option: SideMenuOptionModel
    @Binding var selectedOption: SideMenuOptionModel?
    @Environment(\.colorScheme) var colorScheme
    
    private var isSelected: Bool {
        return selectedOption == option
    }
    
    var body: some View {
        HStack {
            Image(systemName: option.systemImageName)
                .foregroundColor(isSelected ? AppColors.primary : AppColors.primary)
                .frame(width: 24, height: 24)
            
            Text(option.title)
                .font(AppFonts.body)
                .foregroundColor(isSelected ? AppColors.primary : AppColors.primary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isSelected ? AppColors.primary.opacity(0.1) : Color.clear)
        .cornerRadius(10)
    }
}

enum SideMenuOptionModel: Int, CaseIterable, Identifiable {
    case home, add, profile, search
         //admin
//         friends, pro,
  
    
    var id: Int { self.rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .add: return "Add Challenge"
        case .profile: return "Profile"
        case .search: return "Search"
//        case .friends: return "Friends"
//        case .pro: return "Upgrade to Pro"
      //  case .admin: return "Admin"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .home: return "house"
        case .add: return "plus.app"
        case .profile: return "person"
        case .search: return "magnifyingglass"
//        case .friends: return "person.3"
//        case .pro: return "star"
       // case .admin: return "trash"
        }
    }
}
