import Foundation
import Combine

class AchievementService: ObservableObject {
    @Published private(set) var achievements: [Achievement]
    @Published private(set) var currentGoals: [Goal]
    @Published private(set) var weeklyStats: [Date: Int] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let historyService: HistoryService
    private let notificationService = NotificationService.shared
    
    init(historyService: HistoryService) {
        self.historyService = historyService
        self.achievements = Achievement.all
        self.currentGoals = []
        loadAchievements()
        loadGoals()
        loadWeeklyStats()
        checkAchievements()

        historyService.$sessions
            .sink { [weak self] _ in
                self?.updateWeeklyStats()
                self?.checkAchievements()
                self?.updateGoalProgress()
            }
            .store(in: &cancellables)
    }
    
    func checkAchievements() {
        var updated = false
        
        for (index, achievement) in achievements.enumerated() {
            if !achievement.isUnlocked {
                let value = getValue(for: achievement.type)
                if value >= achievement.requiredValue {
                    achievements[index].isUnlocked = true
                    achievements[index].dateUnlocked = Date()
                    updated = true
                    
                    // Schedule achievement notification
                    notificationService.scheduleAchievementNotification(for: achievements[index])
                }
            }
        }
        
        if updated {
            saveAchievements()
        }
    }
    
    func createGoal(type: AchievementType, targetValue: Int, duration: Int) {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? startDate
        
        let goal = Goal(
            id: UUID(),
            type: type,
            targetValue: targetValue,
            currentValue: getValue(for: type),
            startDate: startDate,
            endDate: endDate
        )
        
        currentGoals.append(goal)
        saveGoals()
    }
    
    func updateGoalProgress() {
        for (index, goal) in currentGoals.enumerated() {
            currentGoals[index].currentValue = getValue(for: goal.type)
        }
        saveGoals()
    }
    
    func updateWeeklyStats() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var stats: [Date: Int] = [:]
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i - 6, to: today) {
                stats[date] = 0
            }
        }
        for session in historyService.sessions {
            let sessionDate = calendar.startOfDay(for: session.date)
            if let daysAgo = calendar.dateComponents([.day], from: sessionDate, to: today).day, daysAgo >= 0, daysAgo < 7 {
                stats[sessionDate, default: 0] += 1
            }
        }
        weeklyStats = stats
        saveWeeklyStats()
    }
    
    public func getValue(for type: AchievementType) -> Int {
        switch type {
        case .totalSessions:
            print("totalSessions: \(historyService.totalSessions)")
            return historyService.totalSessions
        case .totalTime:
            print("totalTime: \(historyService.totalDuration)")
            return Int(historyService.totalDuration)
        case .totalCycles:
            print("totalCycles: \(historyService.totalCycles)")
            return historyService.totalCycles
        case .streak:
            let streak = calculateStreak()
            print("streak: \(streak)")
            return streak
        case .modeMaster:
            let mode = calculateModeMastery()
            print("modeMaster: \(mode)")
            return mode
        }
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentDate = today
        var streak = 0
        
        while true {
            let hasSession = historyService.sessions.contains { session in
                calendar.isDate(calendar.startOfDay(for: session.date), inSameDayAs: currentDate)
            }
            
            if hasSession {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateModeMastery() -> Int {
        let modeSessions = historyService.sessions.filter { $0.mode == .box }
        return modeSessions.count
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        }
    }
    
    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(currentGoals) {
            UserDefaults.standard.set(encoded, forKey: "current_goals")
        }
    }
    
    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: "current_goals"),
           let decoded = try? JSONDecoder().decode([Goal].self, from: data) {
            currentGoals = decoded
        }
    }
    
    private func saveWeeklyStats() {
        if let encoded = try? JSONEncoder().encode(weeklyStats) {
            UserDefaults.standard.set(encoded, forKey: "weekly_stats")
        }
    }
    
    private func loadWeeklyStats() {
        if let data = UserDefaults.standard.data(forKey: "weekly_stats"),
           let decoded = try? JSONDecoder().decode([Date: Int].self, from: data) {
            weeklyStats = decoded
        }
    }
    
    func resetAchievements() {
        achievements = Achievement.all
        saveAchievements()
    }
    
    func resetGoals() {
        currentGoals = []
        saveGoals()
    }
    
    func resetWeeklyStats() {
        weeklyStats = [:]
        saveWeeklyStats()
    }
} 
