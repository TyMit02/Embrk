import SwiftUI

struct FriendRequestsView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var pendingRequests: [User] = []
    @State private var processedRequests: String
    @State private var isRefreshing = false
    @State private var selectedUser: User?
    @State private var showingActionSheet = false

    var body: some View {
        List {
            if pendingRequests.isEmpty {
                Text("No pending friend requests")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(pendingRequests, id: \.id) { user in
                    HStack {
                        Text(user.username)
                        Spacer()
                        Button("Respond") {
                            print("DEBUG: Respond button pressed for user: \(user.username)")
                            selectedUser = user
                            showingActionSheet = true
                        }
                        .disabled(processedRequests.contains(user.id ?? ""))
                    }
                }
            }
        }
        .navigationTitle("Friend Requests")
        .onAppear {
            refreshPendingRequests()
        }
        .refreshable {
            await refreshPendingRequestsAsync()
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(title: Text("Respond to Friend Request"), message: Text("Do you want to accept or reject this friend request?"), buttons: [
                .default(Text("Accept")) {
                    if let user = selectedUser {
                        acceptFriendRequest(for: user)
                    }
                },
                .destructive(Text("Reject")) {
                    if let user = selectedUser {
                        rejectFriendRequest(for: user)
                    }
                },
                .cancel()
            ])
        }
    }

    private func refreshPendingRequests() {
        pendingRequests = challengeManager.getPendingFriendRequests()
        processedRequests.removeAll()
        print("Pending requests refreshed. Count: \(pendingRequests.count)")
    }

    private func refreshPendingRequestsAsync() async {
        isRefreshing = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        refreshPendingRequests()
        isRefreshing = false
    }

    private func acceptFriendRequest(for user: User) {
        print("DEBUG: Inside acceptFriendRequest function for user: \(user.username)")
        guard !processedRequests.contains(user.id ?? "") else {
            print("Request for \(user.username) has already been processed.")
            return
        }

        //processedRequests.insert(user.id)

        do {
            print("FriendRequestsView: Attempting to accept friend request from: \(user.username)")
            try challengeManager.acceptFriendRequest(from: user.id ?? "")
            print("FriendRequestsView: Friend request from \(user.username) accepted")
            pendingRequests.removeAll { $0.id == user.id }
            print("FriendRequestsView: Removed processed request from pending list. New count: \(pendingRequests.count)")
        } catch {
            print("Failed to accept friend request: \(error.localizedDescription)")
        }
    }

    private func rejectFriendRequest(for user: User) {
        print("DEBUG: Inside rejectFriendRequest function for user: \(user.username)")
        guard !processedRequests.contains(user.id ?? "") else {
            print("Request for \(user.username) has already been processed.")
            return
        }

       // processedRequests.insert(user.id)

        do {
            print("FriendRequestsView: Attempting to reject friend request from: \(user.username)")
            try challengeManager.rejectFriendRequest(from: user.id ?? "")
            print("FriendRequestsView: Friend request from \(user.username) rejected")
            pendingRequests.removeAll { $0.id == user.id }
            print("FriendRequestsView: Removed processed request from pending list. New count: \(pendingRequests.count)")
        } catch {
            print("Failed to reject friend request: \(error.localizedDescription)")
        }
    }
}

//struct FriendRequestsView_Previews: PreviewProvider {
//    static var previews: some View {
//        FriendRequestsView()
//            .environmentObject(ChallengeManager())
//    }
//}
