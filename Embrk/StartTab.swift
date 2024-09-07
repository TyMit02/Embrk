import SwiftUI

struct StartTab: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @Binding var showMenu: Bool
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(showMenu: $showMenu)
                    .tag(0)
                
                AddChallengeView()
                    .tag(1)
                
                ProfileView()
                    .tag(2)
                
                SearchView()
                    .tag(3)
                
                FriendsView()
                    .tag(4)
                
               
            }
            
            CustomTabBar(selectedTab: $selectedTab)
           
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    withAnimation(.easeInOut) {
                        showMenu.toggle()
                    }
                }) {
                    Image(systemName: "line.3.horizontal")
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 50 {
                        withAnimation(.easeInOut) {
                            showMenu = true
                        }
                    } else if gesture.translation.width < -50 {
                        withAnimation(.easeInOut) {
                            showMenu = false
                        }
                    }
                }
        )
    }
}


struct StartTab_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StartTab(showMenu: .constant(false), selectedTab: .constant(0))
                .environmentObject(ChallengeManager())
        }
    }
}
