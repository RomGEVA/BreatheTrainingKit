import SwiftUI

struct GoalEditorView: View {
    let goal: BreathingGoal?
    let onSave: (BreathingGoal) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var targetValue: TimeInterval = 300
    @State private var period: GoalPeriod = .daily
    @State private var showingSuggestions = false
    
    private var isEditing: Bool {
        goal != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Basic Information
                Section(header: Text("Goal Details")) {
                    TextField("Goal Title", text: $title)
                    
                    HStack {
                        Label("Period", systemImage: "calendar")
                        Spacer()
                        Picker("Period", selection: $period) {
                            ForEach(GoalPeriod.allCases, id: \.self) { period in
                                HStack {
                                    Image(systemName: period.icon)
                                    Text(period.rawValue)
                                }
                                .tag(period)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // MARK: - Target Value
                Section(header: Text("Target Value")) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Duration", systemImage: "timer")
                            Spacer()
                            Text(formatTime(targetValue))
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Minutes: \(Int(targetValue) / 60)")
                                .font(.subheadline)
                            
                            Slider(value: $targetValue, in: 60...7200, step: 60)
                                .accentColor(.blue)
                            
                            Text("Seconds: \(Int(targetValue) % 60)")
                                .font(.subheadline)
                        }
                    }
                }
                
                // MARK: - Quick Presets
                Section(header: Text("Quick Presets")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        PresetButton(title: "5 min", value: 300) {
                            targetValue = 300
                        }
                        
                        PresetButton(title: "10 min", value: 600) {
                            targetValue = 600
                        }
                        
                        PresetButton(title: "15 min", value: 900) {
                            targetValue = 900
                        }
                        
                        PresetButton(title: "30 min", value: 1800) {
                            targetValue = 1800
                        }
                        
                        PresetButton(title: "1 hour", value: 3600) {
                            targetValue = 3600
                        }
                        
                        PresetButton(title: "Custom", value: targetValue) {
                            // Keep current value
                        }
                    }
                }
                
                // MARK: - Goal Suggestions
                Section(header: Text("Suggested Goals")) {
                    Button(action: { showingSuggestions = true }) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                            Text("View Suggestions")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - Goal Preview
                Section(header: Text("Goal Preview")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Target", systemImage: "target")
                            Spacer()
                            Text(formatTime(targetValue))
                                .font(.headline)
                        }
                        
                        HStack {
                            Label("Period", systemImage: period.icon)
                            Spacer()
                            Text(period.rawValue)
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Label("Deadline", systemImage: "calendar")
                            Spacer()
                            Text(calculateDeadline())
                                .font(.subheadline)
                        }
                        
                        if let recommendation = getRecommendation() {
                            HStack {
                                Label("Recommendation", systemImage: "info.circle")
                                Spacer()
                                Text(recommendation)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(title.isEmpty || targetValue < 60)
                }
            }
            .onAppear {
                loadGoal()
            }
            .sheet(isPresented: $showingSuggestions) {
                GoalSuggestionsView { suggestion in
                    title = suggestion.title
                    targetValue = suggestion.targetValue
                    period = suggestion.period
                    showingSuggestions = false
                }
            }
        }
    }
    
    private func loadGoal() {
        guard let goal = goal else { return }
        
        title = goal.title
        targetValue = goal.targetValue
        period = goal.period
    }
    
    private func saveGoal() {
        let newGoal = BreathingGoal(title: title, targetValue: targetValue, period: period)
        
        if let existingGoal = goal {
            var updatedGoal = newGoal
            updatedGoal.id = existingGoal.id
            updatedGoal.startDate = existingGoal.startDate
            updatedGoal.endDate = existingGoal.endDate
            updatedGoal.isActive = existingGoal.isActive
            updatedGoal.currentValue = existingGoal.currentValue
            onSave(updatedGoal)
        } else {
            onSave(newGoal)
        }
        
        dismiss()
    }
    
    private func calculateDeadline() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let deadline = Calendar.current.date(byAdding: period.dateComponent, value: 1, to: Date()) ?? Date()
        return formatter.string(from: deadline)
    }
    
    private func getRecommendation() -> String? {
        let minutes = Int(targetValue) / 60
        
        switch period {
        case .daily:
            if minutes < 5 {
                return "Consider increasing to at least 5 minutes for better benefits"
            } else if minutes > 60 {
                return "This is a substantial daily goal. Make sure it's sustainable."
            }
        case .weekly:
            if minutes < 30 {
                return "Weekly goals should be at least 30 minutes total"
            } else if minutes > 300 {
                return "This is an ambitious weekly goal. Break it into daily sessions."
            }
        case .monthly:
            if minutes < 120 {
                return "Monthly goals should be at least 2 hours total"
            } else if minutes > 1200 {
                return "This is a significant monthly commitment. Plan accordingly."
            }
        }
        
        return nil
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let title: String
    let value: TimeInterval
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(formatTime(value))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Goal Suggestions View

struct GoalSuggestionsView: View {
    let onSelect: (BreathingGoal) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let suggestions = [
        BreathingGoal(title: "Daily Mindfulness", targetValue: 300, period: .daily),
        BreathingGoal(title: "Weekly Wellness", targetValue: 2100, period: .weekly),
        BreathingGoal(title: "Monthly Mastery", targetValue: 9000, period: .monthly),
        BreathingGoal(title: "Stress Relief", targetValue: 600, period: .daily),
        BreathingGoal(title: "Energy Boost", targetValue: 180, period: .daily),
        BreathingGoal(title: "Deep Focus", targetValue: 900, period: .weekly),
        BreathingGoal(title: "Sleep Preparation", targetValue: 300, period: .daily),
        BreathingGoal(title: "Morning Routine", targetValue: 180, period: .daily),
        BreathingGoal(title: "Evening Wind-down", targetValue: 240, period: .daily),
        BreathingGoal(title: "Weekend Recovery", targetValue: 1200, period: .weekly)
    ]
    
    var body: some View {
        NavigationView {
            List(suggestions) { suggestion in
                Button(action: { onSelect(suggestion) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: suggestion.period.icon)
                                Text(suggestion.period.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatTime(suggestion.targetValue))
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Goal Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
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
}
