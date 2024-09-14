import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showMainApp = false
    
    let pages: [OnboardingPage] = [
        OnboardingPage(title: "Welcome to Embrk", description: "Join exciting challenges and track your progress with ease.", imageName: "figure.walk"),
        OnboardingPage(title: "Set Your Goals", description: "Create custom challenges or join community challenges to achieve your fitness goals.", imageName: "target"),
        OnboardingPage(title: "Track Your Progress", description: "Use HealthKit integration to automatically track your activity and update your challenge progress.", imageName: "chart.bar.fill"),
        OnboardingPage(title: "Connect with Friends", description: "Invite friends, share your achievements, and motivate each other to reach new heights.", imageName: "person.3.fill")
    ]
    
    var body: some View {
        if showMainApp {
            Text("Main App View")
                .font(.largeTitle)
        } else {
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count) { index in
                        VStack {
                            Image(systemName: pages[index].imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150, height: 150)
                                .foregroundColor(.blue)
                                .padding()
                            
                            Text(pages[index].title)
                                .font(.title)
                                .fontWeight(.bold)
                                .padding()
                            
                            Text(pages[index].description)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    } else {
                        showMainApp = true
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}