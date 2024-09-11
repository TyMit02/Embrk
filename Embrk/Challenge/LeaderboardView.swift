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