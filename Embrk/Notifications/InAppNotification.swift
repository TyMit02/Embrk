import Foundation

struct InAppNotification: Identifiable, Codable {
    var id = UUID()
    let title: String
    let message: String
    let date: Date
    var isRead: Bool = false
}
