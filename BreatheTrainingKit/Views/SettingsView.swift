import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BreathingViewModel
    @EnvironmentObject var historyService: HistoryService
    @EnvironmentObject var achievementService: AchievementService
    @StateObject private var customPatternService = CustomPatternService()
    @StateObject private var goalService = GoalService()
    
    @State private var showingResetOptions = false
    @State private var showingCustomPatternEditor = false
    @State private var showingGoalEditor = false
    @State private var selectedPattern: CustomBreathingPattern?
    @State private var selectedGoal: BreathingGoal?
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Appearance & Theme
                Section(header: Text("Appearance")) {
                    HStack {
                        Label("Theme", systemImage: "paintbrush.fill")
                        Spacer()
                        Picker("Theme", selection: $viewModel.settings.selectedTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                HStack {
                                    Image(systemName: theme.icon)
                                    Text(theme.rawValue)
                                }
                                .tag(theme)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Label("Breathing Speed", systemImage: "speedometer")
                        Spacer()
                        Picker("Speed", selection: $viewModel.settings.breathingSpeed) {
                            ForEach(BreathingSpeed.allCases, id: \.self) { speed in
                                Text(speed.rawValue).tag(speed)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    if viewModel.settings.breathingSpeed != .normal {
                        Text(viewModel.settings.breathingSpeed.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Audio & Haptics
                Section(header: Text("Audio & Haptics")) {
                    Toggle("Enable Sounds", isOn: $viewModel.settings.isSoundEnabled)
                    
                    if viewModel.settings.isSoundEnabled {
                        HStack {
                            Label("Background Sound", systemImage: "speaker.wave.3.fill")
                            Spacer()
                            Picker("Sound", selection: $viewModel.settings.selectedSound) {
                                ForEach(BreathingSound.allCases, id: \.self) { sound in
                                    HStack {
                                        Image(systemName: sound.icon)
                                        Text(sound.rawValue)
                                    }
                                    .tag(sound)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        HStack {
                            Label("Volume", systemImage: "speaker.wave.2.fill")
                            Slider(value: $viewModel.settings.soundVolume, in: 0...1)
                            Text("\(Int(viewModel.settings.soundVolume * 100))%")
                                .frame(width: 40)
                        }
                    }
                    
                    Toggle("Enable Haptics", isOn: $viewModel.settings.isHapticEnabled)
                    Toggle("Enable Vibration", isOn: $viewModel.settings.isVibrationEnabled)
                }
                
                // MARK: - Breathing Preferences
                Section(header: Text("Breathing Preferences")) {
                    Toggle("Show Breathing Guide", isOn: $viewModel.settings.showBreathingGuide)
                    Toggle("Auto-start Next Session", isOn: $viewModel.settings.autoStartNextSession)
                    
                    HStack {
                        Label("Daily Goal", systemImage: "target")
                        Spacer()
                        Text(formatTime(viewModel.settings.dailyGoal))
                        Button("Edit") {
                            selectedGoal = BreathingGoal(title: "Daily Goal", targetValue: viewModel.settings.dailyGoal, period: .daily)
                            showingGoalEditor = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack {
                        Label("Weekly Goal", systemImage: "calendar.week")
                        Spacer()
                        Text(formatTime(viewModel.settings.weeklyGoal))
                        Button("Edit") {
                            selectedGoal = BreathingGoal(title: "Weekly Goal", targetValue: viewModel.settings.weeklyGoal, period: .weekly)
                            showingGoalEditor = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - Custom Patterns
                Section(header: Text("Custom Breathing Patterns")) {
                    ForEach(customPatternService.customPatterns) { pattern in
                        CustomPatternRow(pattern: pattern) {
                            selectedPattern = pattern
                            showingCustomPatternEditor = true
                        }
                    }
                    
                    Button(action: {
                        showingCustomPatternEditor = true
                    }) {
                        Label("Add New Pattern", systemImage: "plus.circle.fill")
                    }
                }
                
                // MARK: - Personal Goals
                Section(header: Text("Personal Goals")) {
                    ForEach(goalService.activeGoals) { goal in
                        BreathingGoalRow(goal: goal) {
                            selectedGoal = goal
                            showingGoalEditor = true
                        }
                    }
                    
                    Button(action: {
                        showingGoalEditor = true
                    }) {
                        Label("Add New Goal", systemImage: "plus.circle.fill")
                    }
                }
                
                // MARK: - App
                Section(header: Text("App")) {
                    Button(action: rateApp) {
                        Label("Rate App", systemImage: "star.fill")
                    }
                    Button(action: openPrivacyPolicy) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    Button(role: .destructive, action: { showingResetOptions = true }) {
                        Label("Reset All", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCustomPatternEditor) {
                CustomPatternEditorView(
                    pattern: selectedPattern,
                    onSave: { pattern in
                        if let selectedPattern = selectedPattern {
                            customPatternService.updateCustomPattern(pattern)
                        } else {
                            customPatternService.addCustomPattern(pattern)
                        }
                        selectedPattern = nil
                    }
                )
            }
            .sheet(isPresented: $showingGoalEditor) {
                GoalEditorView(
                    goal: selectedGoal,
                    onSave: { goal in
                        if let selectedGoal = selectedGoal {
                            goalService.updateGoal(goal)
                        } else {
                            goalService.createGoal(title: goal.title, targetValue: goal.targetValue, period: goal.period)
                        }
                        selectedGoal = nil
                    }
                )
            }
            .confirmationDialog("What do you want to reset?", isPresented: $showingResetOptions, titleVisibility: .visible) {
                Button("Only History", role: .destructive) {
                    historyService.clearHistory()
                }
                Button("Only Achievements", role: .destructive) {
                    achievementService.resetAchievements()
                    achievementService.resetGoals()
                    achievementService.resetWeeklyStats()
                }
                Button("Only Settings", role: .destructive) {
                    UserDefaults.standard.removeObject(forKey: "selectedMode")
                    UserDefaults.standard.removeObject(forKey: "settingsData")
                }
                Button("Only Custom Patterns", role: .destructive) {
                    customPatternService.customPatterns.removeAll()
                }
                Button("Only Personal Goals", role: .destructive) {
                    goalService.personalGoals.removeAll()
                    goalService.completedGoals.removeAll()
                }
                Button("Everything", role: .destructive) {
                    UserDefaults.standard.removeObject(forKey: "achievements")
                    UserDefaults.standard.removeObject(forKey: "current_goals")
                    UserDefaults.standard.removeObject(forKey: "weekly_stats")
                    UserDefaults.standard.removeObject(forKey: "breathing_sessions")
                    UserDefaults.standard.removeObject(forKey: "selectedMode")
                    UserDefaults.standard.removeObject(forKey: "settingsData")
                    historyService.clearHistory()
                    achievementService.resetAchievements()
                    achievementService.resetGoals()
                    achievementService.resetWeeklyStats()
                    customPatternService.customPatterns.removeAll()
                    goalService.personalGoals.removeAll()
                    goalService.completedGoals.removeAll()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func openPrivacyPolicy() {
        guard let url = URL(string: "https://telegra.ph/Privacy-Policy-for-BreatheTraining-08-26") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Custom Pattern Row
// Note: CustomPatternRow is defined in CustomPatternSelectorView.swift to avoid duplication

// MARK: - Goal Row
// Note: GoalRow is defined in GoalEditorView.swift to avoid duplication

// MARK: - Breathing Goal Row

struct BreathingGoalRow: View {
    let goal: BreathingGoal
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: goal.period.icon)
                        Text(goal.title)
                            .font(.headline)
                    }
                    
                    ProgressView(value: goal.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    HStack {
                        Text("\(goal.progressPercentage)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatTime(goal.timeRemaining))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: goal.statusIcon)
                        .foregroundColor(goal.statusColor)
                        .font(.title2)
                    
                    Text("\(goal.daysRemaining) days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 
