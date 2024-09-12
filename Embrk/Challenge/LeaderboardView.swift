//
//  LeaderboardView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//

import Swift
import SwiftUI

 struct LeaderboardView: View {
        @ObservedObject var leaderboardManager: LeaderboardManager
        let challengeId: String
        
        var body: some View {
            List {
                ForEach(leaderboardManager.entries) { entry in
                    HStack {
                        Text(entry.username)
                        Spacer()
                        Text("Score: \(entry.score)")
                    }
                }
            }
            .onAppear {
                leaderboardManager.fetchLeaderboard(forChallenge: challengeId)
            }
        }
    }
