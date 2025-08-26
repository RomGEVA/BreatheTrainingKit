import SwiftUI

struct BreathingView: View {
    @EnvironmentObject var viewModel: BreathingViewModel
    @EnvironmentObject var historyService: HistoryService
    @EnvironmentObject var achievementService: AchievementService
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSettings = false
    @State private var showingAchievement = false
    @State private var currentAchievement: Achievement?
    @State private var animateBackground = false
    @State private var particles: [Particle] = []
    @State private var showPulse = false
    @AppStorage("selectedMode") private var selectedMode: BreathingMode = .box
    @State private var isBreathing = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                WaveBackground()

                VStack {
                    Spacer(minLength: geo.size.height * 0.08)

                    HStack(spacing: geo.size.width * 0.06) {
                        GlassCard(title: "Cycles", value: "\(viewModel.completedCycles)", icon: "arrow.triangle.2.circlepath")
                        GlassCard(title: "Time", value: formatTime(viewModel.totalSessionTime), icon: "clock")
                    }
                    .padding(.horizontal, geo.size.width * 0.05)

                    BreathingCircleView(
                        phase: viewModel.currentPhase,
                        timeRemaining: viewModel.timeRemaining,
                        scale: viewModel.scale,
                        isBreathing: isBreathing,
                        size: min(max(min(geo.size.width, geo.size.height) * 0.6, 140), 320),
                        fontSize: geo.size.width * 0.07
                    )
                    .padding(.vertical, geo.size.height * 0.02)

                    // Mode picker
                    GlassModePicker(selectedMode: $selectedMode)
                        .padding(.horizontal, geo.size.width * 0.08)
                        .padding(.top, geo.size.height * 0.01)

                    // Start/Stop button
                    GradientButton(
                        title: viewModel.isRunning ? "Stop" : "Start",
                        isRunning: viewModel.isRunning,
                        action: {
                            if viewModel.isRunning {
                                handleSessionEnd()
                                viewModel.stopBreathing()
                            } else {
                                viewModel.startBreathing()
                            }
                        }
                    )
                    .frame(height: max(44, geo.size.height * 0.07))
                    .padding(.top, geo.size.height * 0.02)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: -geo.size.height * 0.08)

                VStack {
                    Spacer()
                    GlassTabBar(
                        selectedTab: $viewModel.selectedTab,
                        onHistoryTap: { viewModel.showingHistory = true },
                        onStatsTap: { viewModel.showingStats = true },
                        onAchievementsTap: { viewModel.showingAchievements = true },
                        onSettingsTap: { showingSettings = true }
                    )
                    .padding(.bottom, geo.safeAreaInsets.bottom + geo.size.height * 0.01)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $viewModel.showingHistory) {
                HistoryView()
            }
            .sheet(isPresented: $viewModel.showingAchievements) {
                AchievementsView()
            }
            .sheet(isPresented: $viewModel.showingStats) {
                StatsView()
            }
            .overlay {
                if showingAchievement, let achievement = currentAchievement {
                    AchievementUnlockedView(achievement: achievement)
                }
            }
            .onChange(of: achievementService.achievements) { newAchievements in
                if let unlocked = newAchievements.first(where: { $0.isUnlocked && $0.dateUnlocked?.timeIntervalSinceNow ?? 0 > -1 }) {
                    currentAchievement = unlocked
                    showingAchievement = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showingAchievement = false
                    }
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func handleSessionEnd() {
        print("handleSessionEnd: cycles=\(viewModel.completedCycles), time=\(viewModel.totalSessionTime)")
        guard viewModel.completedCycles > 0, viewModel.totalSessionTime > 0 else { print("Session not saved: zero cycles or time"); return }
        let session = BreathingSession(
            id: UUID(),
            date: Date(),
            duration: viewModel.totalSessionTime,
            completedCycles: viewModel.completedCycles,
            mode: viewModel.selectedMode
        )
        print("Saving session: \(session)")
        historyService.addSession(session)
        print("History sessions after add: \(historyService.sessions)")
        viewModel.completedCycles = 0
        viewModel.totalSessionTime = 0
    }
}

// --- GlassCard ---
struct GlassCard: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 22)
        .background(
            BlurView(style: .systemUltraThinMaterialDark)
                .background(Color.white.opacity(0.06))
        )
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
    }
}

// --- GlassModePicker ---
struct GlassModePicker: View {
    @Binding var selectedMode: BreathingMode
    var body: some View {
        HStack(spacing: 0) {
            ForEach(BreathingMode.allCases, id: \.self) { mode in
                Button(action: { selectedMode = mode }) {
                    Text(mode.rawValue)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(selectedMode == mode ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            selectedMode == mode ? Color.white.opacity(0.12) : Color.clear
                        )
                }
            }
        }
        .background(
            BlurView(style: .systemUltraThinMaterialDark)
                .background(Color.white.opacity(0.04))
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
    }
}

// --- GradientButton ---
struct GradientButton: View {
    let title: String
    let isRunning: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: isRunning ? [Color("ff416c"), Color("ff4b2b")] : [Color.yellow, Color.white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(18)
                .shadow(color: isRunning ? Color("ff416c").opacity(0.3) : Color("4facfe").opacity(0.3), radius: 16, x: 0, y: 8)
        }
    }
}

// --- GlassTabBar ---
struct GlassTabBar: View {
    @Binding var selectedTab: TabType
    let onHistoryTap: () -> Void
    let onStatsTap: () -> Void
    let onAchievementsTap: () -> Void
    let onSettingsTap: () -> Void
    var body: some View {
        HStack {
            Spacer()
            TabBarButton(icon: "clock.arrow.circlepath", isSelected: selectedTab == .history, action: { selectedTab = .history; onHistoryTap() })
            Spacer()
            TabBarButton(icon: "chart.bar.fill", isSelected: selectedTab == .stats, action: { selectedTab = .stats; onStatsTap() })
            Spacer()
            TabBarButton(icon: "trophy.fill", isSelected: selectedTab == .achievements, action: { selectedTab = .achievements; onAchievementsTap() })
            Spacer()
            TabBarButton(icon: "gear", isSelected: selectedTab == .settings, action: { selectedTab = .settings; onSettingsTap() })
            Spacer()
        }
        .padding(.vertical, 10)
        .background(
            BlurView(style: .systemUltraThinMaterialDark)
                .background(Color.white.opacity(0.04))
        )
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: -2)
    }
}

struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(width: 44, height: 44)
                .background(
                    isSelected ? Color.white.opacity(0.12) : Color.clear
                )
                .clipShape(Circle())
        }
    }
}

// --- BlurView ---
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct PulseEffect: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.white.opacity(0.5), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
            )
            .frame(width: 400, height: 400)
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    let scale: CGFloat
    let opacity: Double
}

struct ParticleView: View {
    let particles: [Particle]
    @State private var time: Double = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let x = particle.position.x + particle.velocity.x * time
                    let y = particle.position.y + particle.velocity.y * time
                    
                    context.opacity = particle.opacity
                    context.fill(
                        Circle().path(in: CGRect(x: x, y: y, width: 4, height: 4)),
                        with: .color(.white)
                    )
                }
            }
            .onChange(of: timeline.date) { _ in
                time += 0.1
            }
        }
    }
}

struct AnimatedBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("1a2a6c"),
                    Color("b21f1f"),
                    Color("fdbb2d")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

struct Wave: Shape {
    var phase: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5
        let wavelength = width * 0.8
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / wavelength
            let sine = sin(relativeX + phase)
            let y = midHeight + sine * height * 0.25
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct BreathingCircleView: View {
    let phase: BreathPhase
    let timeRemaining: Double
    let scale: CGFloat
    let isBreathing: Bool
    let size: CGFloat
    let fontSize: CGFloat
    @State private var rotation = 0.0
    @State private var glowOpacity = 0.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 4
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size - 20, height: size - 20)
                .scaleEffect(scale)
                .shadow(color: .white.opacity(0.2), radius: 20)
            
            ForEach(0..<8) { index in
                Circle()
                    .fill(.white)
                    .frame(width: 4, height: 4)
                    .offset(y: -size * 0.5)
                    .rotationEffect(.degrees(Double(index) * 45 + rotation))
            }
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(glowOpacity), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .blur(radius: 20)
            
            VStack(spacing: 8) {
                Text(phase.rawValue)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.white)
                Text(String(format: "%.1f", timeRemaining))
                    .font(.system(size: fontSize, weight: .light, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .onChange(of: isBreathing) { breathing in
            glowOpacity = breathing ? 0.5 : 0.0
        }
    }
}

struct AchievementUnlockedView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: achievement.icon)
                .font(.system(size: 48))
                .foregroundColor(.yellow)
            Text("Achievement Unlocked!")
                .font(.title2)
                .fontWeight(.bold)
            Text(achievement.title)
                .font(.title3)
                .fontWeight(.medium)
            Text(achievement.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 10)
        )
        .padding()
    }
}

struct WaveBackground: View {
    @State private var phase: CGFloat = 0
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color.red, Color.orange],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }

            WaveShape(phase: phase, amplitude: 24, frequency: 1.2)
                .fill(Color.white.opacity(0.08))
                .frame(height: 180)
                .offset(y: 180)
                .blur(radius: 8)

            WaveShape(phase: phase + 1, amplitude: 32, frequency: 0.8)
                .fill(Color.white.opacity(0.10))
                .frame(height: 160)
                .offset(y: 220)
                .blur(radius: 12)

            WaveShape(phase: phase + 2, amplitude: 18, frequency: 1.7)
                .fill(Color.blue.opacity(0.07))
                .frame(height: 120)
                .offset(y: 260)
                .blur(radius: 16)
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: .zero)
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let y = sin(relativeX * .pi * 2 * frequency + phase) * amplitude + height / 2
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}

struct RateAppSection: View {
    @State private var rating: Int = 0

    var body: some View {
        VStack(spacing: 12) {
            Text("Rate App")
                .font(.headline)
                .foregroundColor(.white)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(index <= rating ? Color.yellow : Color.gray.opacity(0.5))
                        .onTapGesture {
                            rating = index
                        }
                        .accessibilityLabel("\(index) star\(index > 1 ? "s" : "")")
                }
            }
            Button(action: {
                if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID?action=write-review") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Оценить в App Store")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(LinearGradient(colors: [Color("4facfe"), Color("00f2fe")], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
            }
        }
        .padding()
        .background(BlurView(style: .systemUltraThinMaterialDark).background(Color.white.opacity(0.06)))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    BreathingView()
} 
