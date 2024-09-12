//
//  FriendsView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//

import SwiftUI

struct FriendsView: View {
    @ObservedObject var friendsManager: FriendsManager
       @State private var showingAddFriendSheet = false

       var body: some View {
           List {
               Section(header: Text("Friend Requests")) {
                   ForEach(friendsManager.friendRequests) { request in
                       FriendRequestRow(request: request, friendsManager: friendsManager)
                   }
               }

               Section(header: Text("Friends")) {
                   ForEach(friendsManager.friends) { friend in
                       FriendRow(friend: friend, friendsManager: friendsManager)
                   }
               }
           }
           .navigationTitle("Friends")
           .toolbar {
               ToolbarItem(placement: .primaryAction) {
                   Button(action: { showingAddFriendSheet = true }) {
                       Image(systemName: "person.badge.plus")
                   }
               }
           }
           .sheet(isPresented: $showingAddFriendSheet) {
               AddFriendView(friendsManager: friendsManager)
           }
           .onAppear {
               friendsManager.startListening()
           }
           .onDisappear {
               friendsManager.stopListening()
           }
       }
   }

   struct FriendRequestRow: View {
       let request: FriendRequest
       @ObservedObject var friendsManager: FriendsManager

       var body: some View {
           HStack {
               Text(request.fromUserId) // Replace with username when available
               Spacer()
               Button("Accept") {
                   Task {
                       try? await friendsManager.acceptFriendRequest(request)
                   }
               }
               Button("Decline") {
                   Task {
                       try? await friendsManager.declineFriendRequest(request)
                   }
               }
           }
       }
   }

   struct FriendRow: View {
       let friend: User
       @ObservedObject var friendsManager: FriendsManager
       @State private var showingActionSheet = false

       var body: some View {
           HStack {
               Text(friend.username)
               Spacer()
               Button(action: { showingActionSheet = true }) {
                   Image(systemName: "ellipsis")
               }
           }
           .actionSheet(isPresented: $showingActionSheet) {
               ActionSheet(title: Text("Friend Options"),
                           buttons: [
                               .destructive(Text("Remove Friend")) {
                                   Task {
                                       try? await friendsManager.removeFriend(friend.id!)
                                   }
                               },
                               .destructive(Text("Block User")) {
                                   Task {
                                       try? await friendsManager.blockUser(friend.id!)
                                   }
                               },
                               .cancel()
                           ])
           }
       }
   }

   struct AddFriendView: View {
       @ObservedObject var friendsManager: FriendsManager
       @State private var username = ""
       @Environment(\.presentationMode) var presentationMode

       var body: some View {
           NavigationView {
               Form {
                   TextField("Username", text: $username)
                   Button("Send Friend Request") {
                       Task {
                           // Implement user search and send request
                           // This is a placeholder and needs to be implemented
                           presentationMode.wrappedValue.dismiss()
                       }
                   }
               }
               .navigationTitle("Add Friend")
               .navigationBarItems(trailing: Button("Cancel") {
                   presentationMode.wrappedValue.dismiss()
               })
           }
       }
   }
