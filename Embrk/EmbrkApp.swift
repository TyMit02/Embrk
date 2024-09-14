//
//  EmbrkApp.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/7/24.
//
//
//  EmbrkApp.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/7/24.

import SwiftUI
import Firebase

@main
struct EmbrkApp: App {
    @StateObject private var authManager: AuthManager
    @StateObject private var challengeManager: ChallengeManager
    
    init() {
        FirebaseApp.configure()
        
        let authManager = AuthManager()
               let firestoreService = FirestoreService()
               
               _authManager = StateObject(wrappedValue: authManager)
               _challengeManager = StateObject(wrappedValue: ChallengeManager(authManager: authManager, firestoreService: firestoreService))
        
        // Request HealthKit authorization
        Task {
            do {
                try await HealthKitManager.shared.requestAuthorization()
                print("HealthKit authorization successful")
            } catch {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some Scene {
          WindowGroup {
              ContentView()
                  .environmentObject(authManager)
                  .environmentObject(challengeManager)
          }
      }
  }
