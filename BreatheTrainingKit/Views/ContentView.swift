import SwiftUI

struct ContentView: View {
    @EnvironmentObject var historyService: HistoryService
    @EnvironmentObject var achievementService: AchievementService
    @State private var selectedTab: TabType = .main

    var body: some View {
        ZStack {
            switch selectedTab {
            case .main:
                BreathingView()
            case .history:
                HistoryView()
            case .stats:
                StatsView()
            case .achievements:
                AchievementsView()
            case .settings:
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HistoryService())
        .environmentObject(AchievementService(historyService: HistoryService()))
}
