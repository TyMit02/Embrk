struct ActivityFeed: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Recent Activity")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.medium) {
                    ForEach(challengeManager.recentActivities.prefix(5)) { activity in
                        ActivityCard(activity: activity)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 120)
        }
    }
}

struct ActivityCard: View {
    let activity: ActivityItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: activity.iconName)
                    .foregroundColor(AppColors.primary)
                Text(activity.username)
                    .font(AppFonts.caption)
                    .fontWeight(.bold)
            }
            Text(activity.description)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.text)
                .lineLimit(2)
            Text(activity.timeAgo)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.lightText)
        }
        .padding()
        .frame(width: 200, height: 100)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let username: String
    let description: String
    let timeAgo: String
    let iconName: String
}