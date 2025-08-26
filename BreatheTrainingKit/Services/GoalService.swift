import Foundation
import Combine
import SwiftUI

class GoalService: ObservableObject {
    @Published var personalGoals: [BreathingGoal] = []
    @Published var completedGoals: [BreathingGoal] = []
    @Published var activeGoals: [BreathingGoal] = []
    
    private let userDefaults = UserDefaults.standard
    private let goalsKey = "personalGoals"
    private let completedGoalsKey = "completedGoals"
    
    init() {
        loadGoals()
        updateActiveGoals()
    }
    
    // MARK: - Goal Management
    
    func createGoal(title: String, targetValue: TimeInterval, period: GoalPeriod) {
        let newGoal = BreathingGoal(title: title, targetValue: targetValue, period: period)
        personalGoals.append(newGoal)
        saveGoals()
        updateActiveGoals()
    }
    
    func updateGoal(_ goal: BreathingGoal) {
        if let index = personalGoals.firstIndex(where: { $0.id == goal.id }) {
            personalGoals[index] = goal
            saveGoals()
            updateActiveGoals()
        }
    }
    
    func deleteGoal(_ goal: BreathingGoal) {
        personalGoals.removeAll { $0.id == goal.id }
        saveGoals()
        updateActiveGoals()
    }
    
    func completeGoal(_ goal: BreathingGoal) {
        if let index = personalGoals.firstIndex(where: { $0.id == goal.id }) {
            var updatedGoal = goal
            updatedGoal.isActive = false
            personalGoals[index] = updatedGoal
            completedGoals.append(updatedGoal)
            saveGoals()
            updateActiveGoals()
        }
    }
    
    func resetGoal(_ goal: BreathingGoal) {
        if let index = personalGoals.firstIndex(where: { $0.id == goal.id }) {
            var updatedGoal = goal
            updatedGoal.currentValue = 0
            updatedGoal.startDate = Date()
            updatedGoal.endDate = Calendar.current.date(byAdding: goal.period.dateComponent, value: 1, to: Date()) ?? Date()
            updatedGoal.isActive = true
            personalGoals[index] = updatedGoal
            saveGoals()
            updateActiveGoals()
        }
    }
    
    // MARK: - Progress Tracking
    
    func updateProgress(for goalId: UUID, additionalValue: TimeInterval) {
        if let index = personalGoals.firstIndex(where: { $0.id == goalId }) {
            personalGoals[index].currentValue += additionalValue
            
            // Check if goal is completed
            if personalGoals[index].isCompleted {
                completeGoal(personalGoals[index])
            } else {
                saveGoals()
                updateActiveGoals()
            }
        }
    }
    
    func getProgressForPeriod(_ period: GoalPeriod) -> TimeInterval {
        let now = Date()
        let startOfPeriod: Date
        
        switch period {
        case .daily:
            startOfPeriod = Calendar.current.startOfDay(for: now)
        case .weekly:
            startOfPeriod = Calendar.current.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .monthly:
            startOfPeriod = Calendar.current.dateInterval(of: .month, for: now)?.start ?? now
        }
        
        return personalGoals
            .filter { $0.period == period && $0.startDate >= startOfPeriod }
            .reduce(0) { $0 + $1.currentValue }
    }
    
    // MARK: - Goal Suggestions
    
    func getSuggestedGoals() -> [BreathingGoal] {
        let suggestions = [
            BreathingGoal(title: "Daily Mindfulness", targetValue: 300, period: .daily),
            BreathingGoal(title: "Weekly Wellness", targetValue: 2100, period: .weekly),
            BreathingGoal(title: "Monthly Mastery", targetValue: 9000, period: .monthly),
            BreathingGoal(title: "Stress Relief", targetValue: 600, period: .daily),
            BreathingGoal(title: "Energy Boost", targetValue: 180, period: .daily),
            BreathingGoal(title: "Deep Focus", targetValue: 900, period: .weekly)
        ]
        
        return suggestions.filter { suggestion in
            !personalGoals.contains { $0.title == suggestion.title }
        }
    }
    
    func getRecommendedGoalValue(for period: GoalPeriod) -> TimeInterval {
        let currentProgress = getProgressForPeriod(period)
        
        switch period {
        case .daily:
            return max(300, currentProgress * 1.2) // 20% increase or minimum 5 minutes
        case .weekly:
            return max(2100, currentProgress * 1.15) // 15% increase or minimum 35 minutes
        case .monthly:
            return max(9000, currentProgress * 1.1) // 10% increase or minimum 2.5 hours
        }
    }
    
    // MARK: - Analytics
    
    func getGoalCompletionRate() -> Double {
        let totalGoals = personalGoals.count + completedGoals.count
        guard totalGoals > 0 else { return 0.0 }
        
        return Double(completedGoals.count) / Double(totalGoals)
    }
    
    func getAverageGoalDuration() -> TimeInterval {
        let activeGoals = personalGoals.filter { $0.isActive }
        guard !activeGoals.isEmpty else { return 0 }
        
        let totalDuration = activeGoals.reduce(0) { $0 + $1.targetValue }
        return totalDuration / Double(activeGoals.count)
    }
    
    func getStreakDays() -> Int {
        var streak = 0
        let calendar = Calendar.current
        let today = Date()
        
        for dayOffset in 0...365 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { break }
            
            let dailyProgress = getProgressForPeriod(.daily)
            if dailyProgress > 0 {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Private Methods
    
    private func updateActiveGoals() {
        activeGoals = personalGoals.filter { $0.isActive }
    }
    
    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(personalGoals) {
            userDefaults.set(encoded, forKey: goalsKey)
        }
        
        if let encodedCompleted = try? JSONEncoder().encode(completedGoals) {
            userDefaults.set(encodedCompleted, forKey: completedGoalsKey)
        }
    }
    
    private func loadGoals() {
        if let data = userDefaults.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([BreathingGoal].self, from: data) {
            personalGoals = decoded
        }
        
        if let data = userDefaults.data(forKey: completedGoalsKey),
           let decoded = try? JSONDecoder().decode([BreathingGoal].self, from: data) {
            completedGoals = decoded
        }
    }
}

// MARK: - Extensions

extension BreathingGoal {
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var timeRemaining: TimeInterval {
        max(0, targetValue - currentValue)
    }
    
    var isOverdue: Bool {
        Date() > endDate && !isCompleted
    }
    
    var statusColor: Color {
            if isCompleted {
                return .successColor
            } else if isOverdue {
                return .errorColor
            } else if progress > 0.7 {
                return .warningColor
            } else {
                return .infoColor
            }
        }
    
    var statusIcon: String {
        if isCompleted {
            return "checkmark.circle.fill"
        } else if isOverdue {
            return "exclamationmark.circle.fill"
        } else if progress > 0.7 {
            return "clock.fill"
        } else {
            return "circle"
        }
    }
}
