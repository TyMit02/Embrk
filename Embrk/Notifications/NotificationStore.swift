import Foundation

class NotificationStore: ObservableObject {
    @Published var notifications: [InAppNotification] = []
    private let userDefaultsKey = "StoredInAppNotifications"
    
    init() {
        loadNotifications()
    }
    
    func addNotification(title: String, message: String) {
        let newNotification = InAppNotification(title: title, message: message, date: Date())
        notifications.insert(newNotification, at: 0)
        saveNotifications()
    }
    
    func markAsRead(_ notification: InAppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            saveNotifications()
        }
    }
    
    func deleteNotification(_ notification: InAppNotification) {
        notifications.removeAll { $0.id == notification.id }
        saveNotifications()
    }
    
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([InAppNotification].self, from: data) {
            notifications = decoded
        }
    }
}
