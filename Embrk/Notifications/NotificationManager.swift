import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
           UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
               if granted {
                   print("Notification permission granted")
               } else if let error = error {
                   print("Error requesting notification permission: \(error.localizedDescription)")
               }
           }
       }
       
       func checkNotificationSettings() {
           UNUserNotificationCenter.current().getNotificationSettings { settings in
               DispatchQueue.main.async {
                   switch settings.authorizationStatus {
                   case .authorized:
                       print("Notifications are enabled")
                   case .denied:
                       print("Notifications are disabled")
                   case .notDetermined:
                       print("Notification permission not determined")
                   case .provisional:
                       print("Provisional authorization granted")
                   case .ephemeral:
                       print("Ephemeral authorization granted")
                   @unknown default:
                       print("Unknown authorization status")
                   }
               }
           }
       }
       
    
    func scheduleImmediateNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleReminderForChallenge(_ challenge: Challenge) {
        let content = UNMutableNotificationContent()
        content.title = "Challenge Reminder"
        content.body = "Don't forget to complete your task for '\(challenge.title)'"
        content.sound = UNNotificationSound.default
        
        // Set up a daily trigger at a specific time (e.g., 9 AM)
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "challenge-reminder-\(challenge.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling challenge reminder: \(error.localizedDescription)")
            }
        }
    }
    
    func sendFriendRequestNotification(from sender: User) {
           let content = UNMutableNotificationContent()
           content.title = "New Friend Request"
           content.body = "You have a new friend request from \(sender.username)"
           content.sound = UNNotificationSound.default

           let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
           let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

           UNUserNotificationCenter.current().add(request) { error in
               if let error = error {
                   print("Error sending friend request notification: \(error)")
               }
           }
       }
    
    
    func cancelReminderForChallenge(_ challenge: Challenge) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["challenge-reminder-\(challenge.id)"])
    }
}
