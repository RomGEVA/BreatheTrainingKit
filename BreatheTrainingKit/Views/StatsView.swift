import SwiftUI

struct WeekStat: Identifiable {
    let id: Date
    let sessions: Int
    let day: String
}

struct StatsView: View {
    @EnvironmentObject var achievementService: AchievementService
    @Environment(\.dismiss) private var dismiss
    
    private let calendar = Calendar.current
    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    private func makeWeekData() -> [WeekStat] {
        (0..<7).map { index in
            let date = calendar.date(byAdding: .day, value: index - 6, to: Date()) ?? Date()
            let sessions = achievementService.weeklyStats[calendar.startOfDay(for: date)] ?? 0
            let day = weekDays[calendar.component(.weekday, from: date) - 1]
            return WeekStat(id: date, sessions: sessions, day: day)
        }
    }
    
    var body: some View {
        let weekData: [WeekStat] = makeWeekData()
        let achievements: [Achievement] = achievementService.achievements
        let streak: Int = achievementService.getValue(for: .streak)
        return NavigationView {
            List {
                WeeklyActivitySection(weekData: weekData)
                AchievementsProgressSection(achievements: achievements)
                CurrentStreakSection(streak: streak)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WeeklyActivitySection: View {
    let weekData: [WeekStat]
    var body: some View {
        Section(header: Text("Weekly Activity")) {
            VStack(spacing: 20) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weekData) { data in
                        VStack {
                            Text("\(data.sessions)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(height: CGFloat(data.sessions) * 20)
                            Text(data.day)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 150)
                .padding(.vertical)
            }
        }
    }
}

struct AchievementsProgressSection: View {
    let achievements: [Achievement]
    @EnvironmentObject var achievementService: AchievementService
    var body: some View {
        Section(header: Text("Achievements Progress")) {
            ForEach(AchievementType.allCases, id: \.self) { type in
                let filtered: [Achievement] = achievements.filter { $0.type == type }
                let value = achievementService.getValue(for: type)
                let next = filtered.first { !$0.isUnlocked }?.requiredValue ?? filtered.last?.requiredValue ?? 0
                HStack {
                    Image(systemName: typeIcon(for: type))
                        .foregroundColor(.accentColor)
                    Text(type.rawValue)
                    Spacer()
                    Text("\(value)/\(next)")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
            }
        }
    }
    private func typeIcon(for type: AchievementType) -> String {
        switch type {
        case .totalSessions: return "number.circle.fill"
        case .totalTime: return "clock.fill"
        case .totalCycles: return "arrow.triangle.2.circlepath"
        case .streak: return "flame.fill"
        case .modeMaster: return "star.fill"
        }
    }
}

struct CurrentStreakSection: View {
    let streak: Int
    var body: some View {
        Section(header: Text("Current Streak")) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(streak) days")
                    .font(.headline)
            }
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(HistoryService())
        .environmentObject(AchievementService(historyService: HistoryService()))
} 
 