import Foundation
import UIKit

class HapticsManager {
    static let shared = HapticsManager()
    
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        // Initialize the feedback generator
        feedbackGenerator.prepare()
    }
    
    func playSuccessFeedback() {
        feedbackGenerator.notificationOccurred(.success)
    }
    
    func playErrorFeedback() {
        feedbackGenerator.notificationOccurred(.error)
    }
    
    func playWarningFeedback() {
        feedbackGenerator.notificationOccurred(.warning)
    }
}
