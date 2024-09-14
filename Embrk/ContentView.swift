//
//  ContentView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var selectedTab = 0
    @State private var showMenu = false
    @StateObject private var friendsManager = FriendsManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    let timer = Timer.publish(every: 3600, on: .main, in: .common).autoconnect() // Check every hour
    
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else if authManager.isLoggedIn {
                loggedInView
            } else {
                LoginView(isLoggedIn: $authManager.isLoggedIn)
            }
        }
        .onReceive(timer) { _ in
            if authManager.isLoggedIn {
                challengeManager.checkAndHandleCompletedChallenges()
            }
        }
    }
    
    private var loggedInView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                mainContent
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: showMenu ? geometry.size.width * 0.7 : 0)
                    .disabled(showMenu)
                
                if showMenu {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                showMenu = false
                            }
                        }
                }
                
                SideMenuView(isShowing: $showMenu, selectedTab: $selectedTab)
                    .frame(width: min(geometry.size.width * 0.7, 300))
                    .offset(x: showMenu ? 0 : -min(geometry.size.width * 0.7, 300))
            }
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.width > 50 {
                            withAnimation(.easeInOut) {
                                showMenu = true
                            }
                        } else if gesture.translation.width < -50 && showMenu {
                            withAnimation(.easeInOut) {
                                showMenu = false
                            }
                        }
                    }
            )
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            ZStack {
                HomeView(showMenu: $showMenu)
                    .opacity(selectedTab == 0 ? 1 : 0)
                AddChallengeView()
                    .opacity(selectedTab == 1 ? 1 : 0)
                ProfileView()
                    .opacity(selectedTab == 2 ? 1 : 0)
                SearchView()
                    .opacity(selectedTab == 3 ? 1 : 0)
                FriendsView(friendsManager: friendsManager)
                    .opacity(selectedTab == 4 ? 1 : 0)
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            
            Spacer(minLength: 0)
            
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}
