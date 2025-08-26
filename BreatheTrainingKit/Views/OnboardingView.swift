import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

let onboardingPages = [
    OnboardingPage(image: "wind", title: "Welcome to BreatheNow", description: "Master your breath. Reduce stress. Improve focus."),
    OnboardingPage(image: "circle.grid.cross", title: "Box & 4-7-8 Breathing", description: "Choose your favorite technique and follow the animated guide."),
    OnboardingPage(image: "chart.bar.fill", title: "Track Progress", description: "See your stats, streaks, and achievements. Stay motivated!"),
    OnboardingPage(image: "gearshape.fill", title: "Personalize", description: "Sounds, haptics, reminders, and more. Make it yours.")
]

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var page = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                TabView(selection: $page) {
                    ForEach(Array(onboardingPages.enumerated()), id: \.offset) { idx, pageData in
                        VStack(spacing: geo.size.height * 0.04) {
                            Spacer()
                            Image(systemName: pageData.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.28, height: geo.size.width * 0.28)
                                .foregroundColor(.white)
                                .shadow(radius: 8)
                            Text(pageData.title)
                                .font(.system(size: geo.size.width * 0.08, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Text(pageData.description)
                                .font(.system(size: geo.size.width * 0.05))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, geo.size.width * 0.08)
                            Spacer()
                            if idx == onboardingPages.count - 1 {
                                Button(action: {
                                    hasSeenOnboarding = true
                                }) {
                                    Text("Get Started")
                                        .font(.system(size: geo.size.width * 0.055, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing))
                                        .cornerRadius(16)
                                        .padding(.horizontal, geo.size.width * 0.12)
                                }
                                .padding(.bottom, geo.size.height * 0.06)
                            }
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            }
        }
    }
}

#Preview {
    OnboardingView()
} 
 