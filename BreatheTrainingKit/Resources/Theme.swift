import SwiftUI

// MARK: - Color Extensions

extension Color {
    // MARK: - Calm Theme
//    static let calmPrimary = Color(red: 0.4, green: 0.7, blue: 0.8)
//    static let calmSecondary = Color(red: 0.6, green: 0.8, blue: 0.9)
//    static let calmAccent = Color(red: 0.2, green: 0.5, blue: 0.6)
//    
//    // MARK: - Energize Theme
//    static let energizePrimary = Color(red: 0.9, green: 0.6, blue: 0.2)
//    static let energizeSecondary = Color(red: 1.0, green: 0.8, blue: 0.4)
//    static let energizeAccent = Color(red: 0.8, green: 0.4, blue: 0.1)
//    
//    // MARK: - Focus Theme
//    static let focusPrimary = Color(red: 0.3, green: 0.6, blue: 0.9)
//    static let focusSecondary = Color(red: 0.5, green: 0.7, blue: 1.0)
//    static let focusAccent = Color(red: 0.1, green: 0.4, blue: 0.7)
//    
//    // MARK: - Sleep Theme
//    static let sleepPrimary = Color(red: 0.4, green: 0.3, blue: 0.8)
//    static let sleepSecondary = Color(red: 0.6, green: 0.5, blue: 0.9)
//    static let sleepAccent = Color(red: 0.2, green: 0.1, blue: 0.6)
//    
//    // MARK: - Custom Theme
//    static let customPrimary = Color(red: 0.7, green: 0.5, blue: 0.8)
//    static let customSecondary = Color(red: 0.8, green: 0.6, blue: 0.9)
//    static let customAccent = Color(red: 0.5, green: 0.3, blue: 0.6)
    
    // MARK: - Breathing Phase Colors
    static let inhaleColor = Color.blue
    static let holdColor = Color.green
    static let exhaleColor = Color.orange
    static let pauseColor = Color.purple
    
    // MARK: - Status Colors
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red
    static let infoColor = Color.blue
    
    // MARK: - Background Colors
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    
    // MARK: - Text Colors
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .calm
    
    static let shared = ThemeManager()
    
    private init() {
        // Load saved theme from UserDefaults
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
    }
    
    func applyTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
    }
    
    func getPrimaryColor() -> Color {
        switch currentTheme {
        case .calm: return .calmPrimary
        case .energize: return .energizePrimary
        case .focus: return .focusPrimary
        case .sleep: return .sleepPrimary
        case .custom: return .customPrimary
        }
    }
    
    func getSecondaryColor() -> Color {
        switch currentTheme {
        case .calm: return .calmSecondary
        case .energize: return .energizeSecondary
        case .focus: return .focusSecondary
        case .sleep: return .sleepSecondary
        case .custom: return .customSecondary
        }
    }
    
    func getAccentColor() -> Color {
        switch currentTheme {
        case .calm: return .calmAccent
        case .energize: return .energizeAccent
        case .focus: return .focusAccent
        case .sleep: return .sleepAccent
        case .custom: return .customAccent
        }
    }
    
    func getBackgroundGradient() -> LinearGradient {
        switch currentTheme {
        case .calm:
            return LinearGradient(
                colors: [.calmPrimary.opacity(0.1), .calmSecondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .energize:
            return LinearGradient(
                colors: [.energizePrimary.opacity(0.1), .energizeSecondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .focus:
            return LinearGradient(
                colors: [.focusPrimary.opacity(0.1), .focusSecondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sleep:
            return LinearGradient(
                colors: [.sleepPrimary.opacity(0.1), .sleepSecondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .custom:
            return LinearGradient(
                colors: [.customPrimary.opacity(0.1), .customSecondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Theme Modifiers

struct ThemeModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .accentColor(themeManager.getAccentColor())
            .background(themeManager.getBackgroundGradient())
    }
}

extension View {
    func themed() -> some View {
        self.modifier(ThemeModifier())
    }
}

// MARK: - Breathing Phase Colors

extension BreathPhase {
    var color: Color {
        switch self {
        case .inhale:
            return .inhaleColor
        case .hold1:
            return .holdColor
        case .exhale:
            return .exhaleColor
        case .hold2:
            return .pauseColor
        }
    }
    
    var icon: String {
        switch self {
        case .inhale:
            return "lungs.fill"
        case .hold1:
            return "pause.fill"
        case .exhale:
            return "lungs"
        case .hold2:
            return "pause.fill"
        }
    }
}

// MARK: - Difficulty Colors

extension String {
    var difficultyColor: Color {
        switch self {
        case "Beginner":
            return .successColor
        case "Intermediate":
            return .infoColor
        case "Advanced":
            return .warningColor
        case "Expert":
            return .errorColor
        default:
            return .gray
        }
    }
}


