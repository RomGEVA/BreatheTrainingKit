import Foundation
import Combine
import SwiftUI

enum TabType: String, CaseIterable, Identifiable {
    case main
    case history
    case stats
    case achievements
    case settings

    var id: String { self.rawValue }
}

class BreathingViewModel: ObservableObject {
    @AppStorage("selectedMode") var selectedMode: BreathingMode = .box
    @AppStorage("settingsData") var settingsData: Data = try! JSONEncoder().encode(BreathingSettings.default)
    @Published var currentPhase: BreathPhase = .inhale
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning = false
    @Published var scale: CGFloat = 1.0
    @Published var completedCycles: Int = 0
    @Published var totalSessionTime: TimeInterval = 0
    @Published var showingHistory = false
    @Published var showingSettings = false
    @Published var showingAchievements = false
    @Published var showingStats = false
    @Published var selectedTab: TabType = .main
    @Published var selectedCustomPattern: CustomBreathingPattern?
    @Published var showingCustomPatternSelector = false
    
    private var timer: AnyCancellable?
    private var phaseStartTime: Date?
    private var sessionStartTime: Date?
    private let soundService = SoundService()
    private let customPatternService = CustomPatternService()
    private let goalService = GoalService()
    
    var settings: BreathingSettings {
        get {
            (try? JSONDecoder().decode(BreathingSettings.self, from: settingsData)) ?? .default
        }
        set {
            settingsData = (try? JSONEncoder().encode(newValue)) ?? settingsData
        }
    }
    
    var currentPhaseDuration: TimeInterval {
        if let customPattern = selectedCustomPattern {
            let baseDuration = getCustomPatternPhaseDuration(for: currentPhase)
            return baseDuration * settings.breathingSpeed.multiplier
        } else {
            let baseDuration = selectedMode.phaseDurations[currentPhase] ?? 0
            return baseDuration * settings.breathingSpeed.multiplier
        }
    }
    
    var availablePatterns: [BreathingMode] {
        var patterns: [BreathingMode] = [.box, .relax]
        
        // Add custom patterns as breathing modes
        for customPattern in customPatternService.customPatterns {
            // Convert custom pattern to breathing mode if needed
        }
        
        return patterns
    }
    
    func startBreathing() {
        isRunning = true
        sessionStartTime = Date()
        currentPhase = .inhale
        timeRemaining = currentPhaseDuration
        startTimer()
        
        if settings.isSoundEnabled {
            soundService.playBackgroundSound(settings.selectedSound, volume: settings.soundVolume)
        }
        
        // Update goal progress
        updateGoalProgress()
    }
    
    func stopBreathing() {
        isRunning = false
        timer?.cancel()
        soundService.stopBackgroundSound()
        soundService.stopPhaseSound()
        
        // Save session and update goals
        saveSession()
        resetState()
    }
    
    func selectCustomPattern(_ pattern: CustomBreathingPattern) {
        selectedCustomPattern = pattern
        showingCustomPatternSelector = false
    }
    
    func clearCustomPattern() {
        selectedCustomPattern = nil
    }
    
    private func startTimer() {
        phaseStartTime = Date()
        timeRemaining = currentPhaseDuration
        
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
        
        if settings.isSoundEnabled {
            soundService.playPhaseSound(currentPhase)
        }
        
        if settings.isHapticEnabled {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        }
        
        if settings.isVibrationEnabled {
            // Trigger vibration if supported
        }
    }
    
    private func updateTimer() {
        guard let startTime = phaseStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        timeRemaining = max(0, currentPhaseDuration - elapsed)
        
        if let sessionStart = sessionStartTime {
            totalSessionTime = Date().timeIntervalSince(sessionStart)
        }
        
        if timeRemaining <= 0 {
            moveToNextPhase()
        }
        
        // Update visual feedback based on current phase
        updateVisualFeedback()
    }
    
    private func updateVisualFeedback() {
        let currentDuration = currentPhaseDuration
        let remaining = timeRemaining
        
        switch currentPhase {
        case .inhale:
            let progress = 1.0 - (remaining / currentDuration)
            scale = 1.0 + progress * 0.5
        case .exhale:
            let progress = 1.0 - (remaining / currentDuration)
            scale = 1.5 - progress * 0.5
        case .hold1, .hold2:
            scale = 1.25
        }
    }
    
    private func moveToNextPhase() {
        let phases = BreathPhase.allCases
        guard let currentIndex = phases.firstIndex(of: currentPhase) else { return }
        
        let nextIndex = (currentIndex + 1) % phases.count
        currentPhase = phases[nextIndex]
        
        if currentPhase == .inhale {
            completedCycles += 1
        }
        
        startTimer()
    }
    
    private func resetState() {
        currentPhase = .inhale
        timeRemaining = currentPhaseDuration
        scale = 1.0
        phaseStartTime = nil
        sessionStartTime = nil
        totalSessionTime = 0
        completedCycles = 0
    }
    
    private func getCustomPatternPhaseDuration(for phase: BreathPhase) -> TimeInterval {
        guard let customPattern = selectedCustomPattern else { return 0 }
        
        switch phase {
        case .inhale:
            return customPattern.inhaleDuration
        case .hold1:
            return customPattern.hold1Duration
        case .exhale:
            return customPattern.exhaleDuration
        case .hold2:
            return customPattern.hold2Duration
        }
    }
    
    private func updateGoalProgress() {
        // Update daily and weekly goals
        let sessionDuration = totalSessionTime
        
        // Find active goals and update their progress
        for goal in goalService.activeGoals {
            if goal.period == .daily || goal.period == .weekly {
                goalService.updateProgress(for: goal.id, additionalValue: sessionDuration)
            }
        }
    }
    
    private func saveSession() {
        // Create and save breathing session
        let session = BreathingSession(
            id: UUID(),
            date: Date(),
            duration: totalSessionTime,
            completedCycles: completedCycles,
            mode: selectedMode
        )
        
        // Save to history service
        // This would need to be implemented in HistoryService
    }
    
    func updateSettings(_ newSettings: BreathingSettings) {
        settings = newSettings
        
        // Apply new settings
        if isRunning {
            if settings.isSoundEnabled {
                soundService.playBackgroundSound(settings.selectedSound, volume: settings.soundVolume)
            } else {
                soundService.stopBackgroundSound()
            }
        }
        
        // Update breathing speed if changed
        if timeRemaining > 0 {
            timeRemaining = currentPhaseDuration
        }
    }
    
    // MARK: - Goal Management
    
    func getDailyGoalProgress() -> Double {
        let dailyProgress = goalService.getProgressForPeriod(.daily)
        return min(dailyProgress / settings.dailyGoal, 1.0)
    }
    
    func getWeeklyGoalProgress() -> Double {
        let weeklyProgress = goalService.getProgressForPeriod(.weekly)
        return min(weeklyProgress / settings.weeklyGoal, 1.0)
    }
    
    func getActiveGoals() -> [BreathingGoal] {
        return goalService.activeGoals
    }
    
    func getCompletedGoals() -> [BreathingGoal] {
        return goalService.completedGoals
    }
    
    // MARK: - Custom Pattern Management
    
    func getCustomPatterns() -> [CustomBreathingPattern] {
        return customPatternService.customPatterns
    }
    
    func getFavoritePatterns() -> [CustomBreathingPattern] {
        return customPatternService.favoritePatterns
    }
    
    func addCustomPattern(_ pattern: CustomBreathingPattern) {
        customPatternService.addCustomPattern(pattern)
    }
    
    func updateCustomPattern(_ pattern: CustomBreathingPattern) {
        customPatternService.updateCustomPattern(pattern)
    }
    
    func deleteCustomPattern(_ pattern: CustomBreathingPattern) {
        customPatternService.deleteCustomPattern(pattern)
        
        // Clear selection if deleted pattern was selected
        if selectedCustomPattern?.id == pattern.id {
            selectedCustomPattern = nil
        }
    }
    
    func toggleFavorite(_ pattern: CustomBreathingPattern) {
        customPatternService.toggleFavorite(pattern)
    }
} 
 