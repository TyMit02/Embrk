//
//  VerificationGoalDeterminer.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//


import Foundation

enum VerificationGoalDeterminer {
    static func determineGoal(title: String, description: String, challengeType: ChallengeType) -> Double? {
        let combinedText = (title + " " + description).lowercased()
        
        // Define patterns to look for
        let stepPatterns = [
            "\\b(\\d{1,3}(,\\d{3})*|\\d+)\\s*(k\\s*)?steps\\b",
            "\\bstep\\s*count\\s*of\\s*(\\d{1,3}(,\\d{3})*|\\d+)\\b"
        ]
        
        let distancePatterns = [
            "\\b(\\d+(\\.\\d+)?)\\s*(km|kilometers|miles)\\b",
            "\\brun\\s*(\\d+(\\.\\d+)?)\\s*(km|kilometers|miles)\\b"
        ]
        
        let caloriePatterns = [
            "\\b(\\d+)\\s*calories\\b",
            "\\bburn\\s*(\\d+)\\s*calories\\b"
        ]
        
        func extractNumber(from text: String, using patterns: [String]) -> Double? {
            for pattern in patterns {
                if let range = text.range(of: pattern, options: .regularExpression) {
                    let match = text[range]
                    if let number = Double(match.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                        return number
                    }
                }
            }
            return nil
        }
        
        switch challengeType {
        case .fitness:
            if let steps = extractNumber(from: combinedText, using: stepPatterns) {
                return steps
            }
            if let distance = extractNumber(from: combinedText, using: distancePatterns) {
                // Convert to meters
                if combinedText.contains("km") || combinedText.contains("kilometers") {
                    return distance * 1000
                } else if combinedText.contains("miles") {
                    return distance * 1609.34
                }
            }
            if let calories = extractNumber(from: combinedText, using: caloriePatterns) {
                return calories
            }
        case .education, .miscellaneous, .lifestyle:
            // For now, we're not setting automatic goals for these types
            return nil
        }
        
        return nil
    }
}
