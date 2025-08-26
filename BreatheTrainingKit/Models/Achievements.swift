import Foundation

enum AchievementType: String, Codable, CaseIterable {
    case totalSessions = "Total Sessions"
    case totalTime = "Total Time"
    case totalCycles = "Total Cycles"
    case streak = "Daily Streak"
    case modeMaster = "Mode Master"
}

struct Achievement: Identifiable, Codable, Equatable {
    let id: UUID
    let type: AchievementType
    let title: String
    let description: String
    let requiredValue: Int
    let icon: String
    var isUnlocked: Bool
    var dateUnlocked: Date?
    
    static let all: [Achievement] = [
        // Session Count Achievements
        Achievement(id: UUID(), type: .totalSessions, title: "Beginner", description: "Complete 5 sessions", requiredValue: 5, icon: "1.circle.fill", isUnlocked: false, dateUnlocked: nil),
        Achievement(id: UUID(), type: .totalSessions, title: "Regular", description: "Complete 25 sessions", requiredValue: 25, icon: "2.circle.fill", isUnlocked: false, dateUnlocked: nil),
        Achievement(id: UUID(), type: .totalSessions, title: "Master", description: "Complete 100 sessions", requiredValue: 100, icon: "3.circle.fill", isUnlocked: false, dateUnlocked: nil),
        
        // Time Achievements
        Achievement(id: UUID(), type: .totalTime, title: "1 Minute Breather", description: "Дышите в течение 1 минуты в сумме.", requiredValue: 60, icon: "timer", isUnlocked: false, dateUnlocked: nil),
        Achievement(id: UUID(), type: .totalTime, title: "Time Keeper", description: "Practice for 1 hour total", requiredValue: 3600, icon: "clock.fill", isUnlocked: false, dateUnlocked: nil),
        Achievement(id: UUID(), type: .totalTime, title: "Dedicated", description: "Practice for 5 hours total", requiredValue: 18000, icon: "clock.badge.fill", isUnlocked: false, dateUnlocked: nil),
        
        // Cycle Achievements
        Achievement(id: UUID(), type: .totalCycles, title: "Cycle Starter", description: "Complete 50 cycles", requiredValue: 50, icon: "arrow.triangle.2.circlepath", isUnlocked: false, dateUnlocked: nil),
        Achievement(id: UUID(), type: .totalCycles, title: "Cycle Master", description: "Complete 500 cycles", requiredValue: 500, icon: "arrow.triangle.2.circlepath.circle.fill", isUnlocked: false, dateUnlocked: nil),
        
        // Streak Achievements
        Achievement(id: UUID(), type: .streak, title: "3-Day Streak", description: "Practice for 3 days in a row", requiredValue: 3, icon: "flame.fill", isUnlocked: false, dateUnlocked: nil),
        Achievement(id: UUID(), type: .streak, title: "7-Day Streak", description: "Practice for 7 days in a row", requiredValue: 7, icon: "flame.circle.fill", isUnlocked: false, dateUnlocked: nil),
        
        // Mode Achievements
        Achievement(id: UUID(), type: .modeMaster, title: "Box Master", description: "Complete 10 box breathing sessions", requiredValue: 10, icon: "square.fill", isUnlocked: false, dateUnlocked: nil),
        Achievement(id: UUID(), type: .modeMaster, title: "Relax Master", description: "Complete 10 relax breathing sessions", requiredValue: 10, icon: "leaf.fill", isUnlocked: false, dateUnlocked: nil)
    ]
}

struct Goal: Identifiable, Codable, Equatable {
    let id: UUID
    let type: AchievementType
    let targetValue: Int
    var currentValue: Int
    let startDate: Date
    let endDate: Date
    
    var progress: Double {
        Double(currentValue) / Double(targetValue)
    }
    
    var isCompleted: Bool {
        currentValue >= targetValue
    }
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
} 