import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Spacer()
            tabButton(for: 0, icon: "house")
            Spacer()
            addButton
            Spacer()
            tabButton(for: 2, icon: "person")
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 20) // Add padding at the bottom
        .frame(height: 80) // Increase height to accommodate bottom padding
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
        )
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func tabButton(for tab: Int, icon: String) -> some View {
        Button(action: { selectedTab = tab }) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(selectedTab == tab ? AppColors.primary : AppColors.lightText)
        }
    }
    
    private var addButton: some View {
        Button(action: { selectedTab = 1 }) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(AppColors.primary)
                .clipShape(Circle())
                .shadow(color: AppColors.primary.opacity(0.3), radius: 4, x: 0, y: 4)
        }
    }
}