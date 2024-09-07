
import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @State private var selectedTab = 0
    @State private var showingAlert = false
    @State private var friendToRemove: User?
    @State private var isManagingFriends = false
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                searchBar
                segmentedControl
            }
            .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
            
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack {
                    if selectedTab == 0 {
                        friendsList
                    } else {
                        friendRequestsList
                    }
                    
                    friendActivityFeed
                }
            }
        }
        .navigationBarTitle("Friends", displayMode: .inline)
        .navigationBarItems(trailing: Button("Manage") {
            isManagingFriends = true
        })
        .sheet(isPresented: $isManagingFriends) {
            ManageFriendsView()
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    
    private var searchBar: some View {
        TextField("Search friends", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
    }
    
    private var segmentedControl: some View {
        Picker("Friend View", selection: $selectedTab) {
            Text("Friends").tag(0)
            Text("Requests").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    private var friendsList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredFriends, id: \.id) { friend in
                    NavigationLink(destination: UserProfileView(user: friend)) {
                        FriendRow(friend: friend, showRemoveButton: false) {
                            friendToRemove = friend
                            showingAlert = true
                        }
                    }
                }
            }
            .padding()
        }
        .alert("Remove Friend", isPresented: $showingAlert, presenting: friendToRemove) { friend in
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                challengeManager.removeFriend(friend.id ?? "")
                HapticsManager.shared.playWarningFeedback()
            }
        } message: { friend in
            Text("Are you sure you want to remove \(friend.username) from your friends list?")
        }
    }
    
    private var friendRequestsList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(challengeManager.getPendingFriendRequests(), id: \.id) { user in
                    FriendRequestRow(user: user, onAccept: {
                        acceptFriendRequest(for: user)
                    }, onReject: {
                        rejectFriendRequest(for: user)
                    })
                }
            }
            .padding()
        }
    }
    
    private var friendActivityFeed: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Friend Activity")
                .font(AppFonts.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(challengeManager.getFriendActivities(), id: \.id) { activity in
                        FriendActivityCard(activity: activity)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
    }
    
    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return challengeManager.getFriends()
        } else {
            return challengeManager.getFriends().filter {
                $0.username.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    private func acceptFriendRequest(for user: User) {
        do {
            try challengeManager.acceptFriendRequest(from: user.id ?? "")
            HapticsManager.shared.playSuccessFeedback()
        } catch {
            print("Failed to accept friend request: \(error.localizedDescription)")
        }
    }
    
    private func rejectFriendRequest(for user: User) {
        do {
            try challengeManager.rejectFriendRequest(from: user.id ?? "")
            HapticsManager.shared.playWarningFeedback()
        } catch {
            print("Failed to reject friend request: \(error.localizedDescription)")
        }
    }
}

struct FriendRow: View {
    let friend: User
    let showRemoveButton: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(AppColors.primary)
            
            VStack(alignment: .leading) {
                Text(friend.username)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                Text(friend.email)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.lightText)
            }
            
            Spacer()
            
            if showRemoveButton {
                Button(action: onRemove) {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct FriendRequestRow: View {
    let user: User
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(AppColors.secondary)
            
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                Text("Wants to be your friend")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.lightText)
            }
            
            Spacer()
            
            HStack {
                Button(action: onAccept) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Button(action: onReject) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct FriendActivityCard: View {
    let activity: FriendActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(activity.description)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.text)
                .lineLimit(2)
            
            Text(activity.timestamp, style: .relative)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
        }
        .padding()
        .frame(width: 150, height: 100)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(10)
    }
}

struct ManageFriendsView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                ForEach(challengeManager.getFriends(), id: \.id) { friend in
                    FriendRow(friend: friend, showRemoveButton: true) {
                        challengeManager.removeFriend(friend.id ?? "")
                        HapticsManager.shared.playWarningFeedback()
                    }
                }
            }
            .listStyle(PlainListStyle())
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Manage Friends", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
}

//struct FriendsView_Previews: PreviewProvider {
//    static var previews: some View {
//        let challengeManager = ChallengeManager()
//        // Add some sample data for preview
//        challengeManager.users = [
//            User(username: "JohnDoe", email: "john@example.com", password: "password"),
//            User(username: "JaneSmith", email: "jane@example.com", password: "password")
//        ]
//        
//        return Group {
//            NavigationView {
//                FriendsView()
//                    .environmentObject(challengeManager)
//            }
//            .previewDisplayName("Light Mode")
//            
//            NavigationView {
//                FriendsView()
//                    .environmentObject(challengeManager)
//                    .preferredColorScheme(.dark)
//            }
//            .previewDisplayName("Dark Mode")
//        }
//    }
//}
