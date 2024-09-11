//
//  LeaderboardView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//


import SwiftUI
import FirebaseFirestore
import FirebaseFirestore

struct LeaderboardEntry: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    var score: Int
    var daysCompleted: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastUpdated: Date
}

class LeaderboardManager: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    private var lastDocument: DocumentSnapshot?
    private let db = Firestore.firestore()
    private let pageSize = 20

    func fetchLeaderboard(forChallenge challengeId: String) {
            let query = db.collection("leaderboards")
                .document(challengeId)
                .collection("entries")
                .order(by: "score", descending: true)
                .limit(to: pageSize)

            query.getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching leaderboard: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }

                self.entries = documents.compactMap { document -> LeaderboardEntry? in
                    try? document.data(as: LeaderboardEntry.self)
                }

                self.lastDocument = documents.last
            }
        }

        func fetchNextPage(forChallenge challengeId: String) {
            guard let lastDocument = lastDocument else { return }

            let query = db.collection("leaderboards")
                .document(challengeId)
                .collection("entries")
                .order(by: "score", descending: true)
                .start(afterDocument: lastDocument)
                .limit(to: pageSize)

            query.getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching next page: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No more documents")
                    return
                }

                let newEntries = documents.compactMap { document -> LeaderboardEntry? in
                    try? document.data(as: LeaderboardEntry.self)
                }

                self.entries.append(contentsOf: newEntries)
                self.lastDocument = documents.last
            }
        }

        func updateScore(forChallenge challengeId: String, userId: String, daysCompleted: Int, currentStreak: Int, challengeDifficulty: String) {
            let entryRef = db.collection("leaderboards")
                .document(challengeId)
                .collection("entries")
                .document(userId)

            db.runTransaction({ (transaction, errorPointer) -> Any? in
                let entryDocument: DocumentSnapshot
                do {
                    try entryDocument = transaction.getDocument(entryRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                var entry: LeaderboardEntry
                if let existingEntry = try? entryDocument.data(as: LeaderboardEntry.self) {
                    entry = existingEntry
                } else {
                    // Fetch user data to get the username
                    let userDocument: DocumentSnapshot
                    do {
                        try userDocument = transaction.getDocument(self.db.collection("users").document(userId))
                    } catch let fetchError as NSError {
                        errorPointer?.pointee = fetchError
                        return nil
                    }
                    
                    guard let username = userDocument.data()?["username"] as? String else {
                        let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Username not found"])
                        errorPointer?.pointee = error
                        return nil
                    }
                    
                    entry = LeaderboardEntry(userId: userId, username: username, score: 0, daysCompleted: 0, currentStreak: 0, longestStreak: 0, lastUpdated: Date())
                }

                // Update entry
                entry.daysCompleted = daysCompleted
                entry.currentStreak = currentStreak
                entry.longestStreak = max(entry.longestStreak, currentStreak)
                entry.score = self.calculateScore(daysCompleted: daysCompleted, currentStreak: currentStreak, longestStreak: entry.longestStreak, challengeDifficulty: challengeDifficulty)
                entry.lastUpdated = Date()

                // Set the updated entry
                do {
                    try transaction.setData(from: entry, forDocument: entryRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                return nil
            }) { (object, error) in
                if let error = error {
                    print("Error updating leaderboard: \(error)")
                } else {
                    print("Leaderboard updated successfully")
                    // Refresh the leaderboard if needed
                    self.fetchLeaderboard(forChallenge: challengeId)
                }
            }
        }

        private func calculateScore(daysCompleted: Int, currentStreak: Int, longestStreak: Int, challengeDifficulty: String) -> Int {
            let baseScore = daysCompleted * 10
            let streakBonus = currentStreak * 5
            let longestStreakBonus = longestStreak * 2
            
            let difficultyMultiplier: Double
            switch challengeDifficulty.lowercased() {
            case "easy":
                difficultyMultiplier = 1.0
            case "medium":
                difficultyMultiplier = 1.2
            case "hard":
                difficultyMultiplier = 1.5
            default:
                difficultyMultiplier = 1.0
            }
            
            return Int(Double(baseScore + streakBonus + longestStreakBonus) * difficultyMultiplier)
        }
    
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
    
    }
