import Foundation

struct BreathingSettings: Codable {
    var isSoundEnabled: Bool
    var isVibrationEnabled: Bool
    var isHapticEnabled: Bool
    var soundVolume: Double
    var selectedSound: BreathingSound
    var selectedTheme: AppTheme
    var breathingSpeed: BreathingSpeed
    var customPatterns: [CustomBreathingPattern]
    var dailyGoal: TimeInterval
    var weeklyGoal: TimeInterval
    var showBreathingGuide: Bool
    var autoStartNextSession: Bool
    
    static let `default` = BreathingSettings(
        isSoundEnabled: true,
        isVibrationEnabled: true,
        isHapticEnabled: true,
        soundVolume: 0.7,
        selectedSound: .nature,
        selectedTheme: .calm,
        breathingSpeed: .normal,
        customPatterns: [],
        dailyGoal: 300, // 5 minutes
        weeklyGoal: 2100, // 35 minutes
        showBreathingGuide: true,
        autoStartNextSession: false
    )
}

enum BreathingSound: String, CaseIterable, Codable {
    case nature = "Nature"
    case ocean = "Ocean"
    case rain = "Rain"
    case forest = "Forest"
    case whiteNoise = "White Noise"
    case meditation = "Meditation"
    
    var filename: String {
        switch self {
        case .nature: return "nature_ambient"
        case .ocean: return "ocean_waves"
        case .rain: return "rain_ambient"
        case .forest: return "forest_ambient"
        case .whiteNoise: return "white_noise"
        case .meditation: return "meditation_bells"
        }
    }
    
    var icon: String {
        switch self {
        case .nature: return "leaf.fill"
        case .ocean: return "water.waves"
        case .rain: return "cloud.rain.fill"
        case .forest: return "tree.fill"
        case .whiteNoise: return "speaker.wave.3.fill"
        case .meditation: return "bell.fill"
        }
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case calm = "Calm"
    case energize = "Energize"
    case focus = "Focus"
    case sleep = "Sleep"
    case custom = "Custom"
    
    var primaryColor: String {
        switch self {
        case .calm: return "calmPrimary"
        case .energize: return "energizePrimary"
        case .focus: return "focusPrimary"
        case .sleep: return "sleepPrimary"
        case .custom: return "customPrimary"
        }
    }
    
    var secondaryColor: String {
        switch self {
        case .calm: return "calmSecondary"
        case .energize: return "energizeSecondary"
        case .focus: return "focusSecondary"
        case .sleep: return "sleepSecondary"
        case .custom: return "customSecondary"
        }
    }
    
    var accentColor: String {
        switch self {
        case .calm: return "calmAccent"
        case .energize: return "energizeAccent"
        case .focus: return "focusAccent"
        case .sleep: return "sleepAccent"
        case .custom: return "customAccent"
        }
    }
    
    var icon: String {
        switch self {
        case .calm: return "leaf.fill"
        case .energize: return "bolt.fill"
        case .focus: return "target"
        case .sleep: return "moon.fill"
        case .custom: return "paintbrush.fill"
        }
    }
}

enum BreathingSpeed: String, CaseIterable, Codable {
    case slow = "Slow"
    case normal = "Normal"
    case fast = "Fast"
    
    var multiplier: Double {
        switch self {
        case .slow: return 1.5
        case .normal: return 1.0
        case .fast: return 0.7
        }
    }
    
    var description: String {
        switch self {
        case .slow: return "Relaxed pace for deep relaxation"
        case .normal: return "Standard breathing rhythm"
        case .fast: return "Quick pace for energy boost"
        }
    }
}

struct CustomBreathingPattern: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var description: String
    var inhaleDuration: TimeInterval
    var hold1Duration: TimeInterval
    var exhaleDuration: TimeInterval
    var hold2Duration: TimeInterval
    var cycles: Int
    var isFavorite: Bool
    var createdAt: Date
    
    var totalDuration: TimeInterval {
        inhaleDuration + hold1Duration + exhaleDuration + hold2Duration
    }
    
    var totalSessionTime: TimeInterval {
        totalDuration * Double(cycles)
    }
    
    init(name: String, description: String, inhale: TimeInterval, hold1: TimeInterval, exhale: TimeInterval, hold2: TimeInterval, cycles: Int) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.inhaleDuration = inhale
        self.hold1Duration = hold1
        self.exhaleDuration = exhale
        self.hold2Duration = hold2
        self.cycles = cycles
        self.isFavorite = false
        self.createdAt = Date()
    }
}

struct BreathingGoal: Identifiable, Codable {
    var id: UUID
    var title: String
    var targetValue: TimeInterval
    var currentValue: TimeInterval
    var period: GoalPeriod
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    
    var progress: Double {
        min(Double(currentValue) / Double(targetValue), 1.0)
    }
    
    var isCompleted: Bool {
        currentValue >= targetValue
    }
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    init(title: String, targetValue: TimeInterval, period: GoalPeriod) {
        self.id = UUID()
        self.title = title
        self.targetValue = targetValue
        self.currentValue = 0
        self.period = period
        self.startDate = Date()
        self.endDate = Calendar.current.date(byAdding: period.dateComponent, value: 1, to: Date()) ?? Date()
        self.isActive = true
    }
}

enum GoalPeriod: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    var dateComponent: Calendar.Component {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "calendar.day"
        case .weekly: return "calendar.week"
        case .monthly: return "calendar.month"
        }
    }
} 