import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @Environment(\.colorScheme) var colorScheme
    
    let pages: [OnboardingPage] = [
        OnboardingPage(title: "Welcome to Challenger", description: "Embark on exciting challenges and push your limits!", imageName: "flag.fill"),
        OnboardingPage(title: "Join Challenges", description: "Participate in various challenges or create your own!", imageName: "person.3.fill"),
        OnboardingPage(title: "Track Progress", description: "Monitor your progress and celebrate achievements!", imageName: "chart.bar.fill"),
        OnboardingPage(title: "Connect with Friends", description: "Compete and motivate each other on your journey!", imageName: "person.2.fill")
    ]
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : AppColors.background
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        hasCompletedOnboarding = true
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: page.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .foregroundColor(AppColors.primary)
            
            Text(page.title)
                .font(AppFonts.title2)
                .fontWeight(.bold)
                .foregroundColor(textColor)
            
            Text(page.description)
                .font(AppFonts.body)
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : AppColors.text
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : AppColors.lightText
    }
}
