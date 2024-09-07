import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @ObservedObject var notificationStore: NotificationStore

    init(challengeManager: ChallengeManager) {
        self.notificationStore = challengeManager.notificationStore
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(notificationStore.notifications) { notification in
                    VStack(alignment: .leading) {
                        Text(notification.title)
                            .font(.headline)
                        Text(notification.message)
                            .font(.subheadline)
                        Text(notification.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .opacity(notification.isRead ? 0.6 : 1.0)
                    .onTapGesture {
                        notificationStore.markAsRead(notification)
                    }
                }
                .onDelete(perform: deleteNotifications)
            }
            .navigationTitle("Notifications")
        }
       
     
        
    }

    private func deleteNotifications(at offsets: IndexSet) {
        offsets.forEach { index in
            let notification = notificationStore.notifications[index]
            notificationStore.deleteNotification(notification)
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        let challengeManager = ChallengeManager()
        return NotificationsView(challengeManager: challengeManager)
            .environmentObject(challengeManager)
    }
}
