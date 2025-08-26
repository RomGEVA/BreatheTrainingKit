import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var achievementService: AchievementService
    @State private var showingNewGoal = false
    @State private var selectedType: AchievementType = .totalSessions
    
    var body: some View {
        NavigationView {
            List {
                CurrentGoalsSection(showingNewGoal: $showingNewGoal)
                AchievementsSection()
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewGoal) {
                NewGoalView()
                    .environmentObject(achievementService)
            }
        }
    }
}

private struct CurrentGoalsSection: View {
    @EnvironmentObject var achievementService: AchievementService
    @Binding var showingNewGoal: Bool

    var body: some View {
        Section(header: Text("Current Goals")) {
            if achievementService.currentGoals.isEmpty {
                Button(action: { showingNewGoal = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Goal")
                    }
                }
            } else {
                ForEach(achievementService.currentGoals) { goal in
                    GoalRow(goal: goal)
                }
                Button(action: { showingNewGoal = true }) {
                    Label("Add Another Goal", systemImage: "plus")
                }
            }
        }
    }
}

private struct AchievementsSection: View {
    @EnvironmentObject var achievementService: AchievementService

    var body: some View {
        Section(header: Text("Achievements")) {
            ForEach(AchievementType.allCases, id: \.self) { type in
                let filtered = achievementService.achievements.filter { $0.type == type }
                let unlocked = filtered.filter { $0.isUnlocked }.count
                let value = achievementService.getValue(for: type)
                let next = filtered.first { !$0.isUnlocked }?.requiredValue ?? filtered.last?.requiredValue ?? 0
                NavigationLink(
                    destination: AchievementTypeView(
                        type: type,
                        achievements: filtered
                    )
                ) {
                    HStack {
                        Image(systemName: typeIcon(for: type))
                            .foregroundColor(.accentColor)
                        Text(type.rawValue)
                        Spacer()
                        Text("\(value)/\(next)")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                        Text("\(unlocked)/\(filtered.count)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
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

struct GoalRow: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.type.rawValue)
                    .font(.headline)
                Spacer()
                Text("\(goal.daysRemaining) days left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: goal.progress)
                .tint(goal.isCompleted ? .green : .blue)
            
            HStack {
                Text("\(goal.currentValue)/\(goal.targetValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AchievementTypeView: View {
    let type: AchievementType
    let achievements: [Achievement]
    
    var body: some View {
        List(achievements) { achievement in
            HStack {
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.title)
                        .font(.headline)
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle(type.rawValue)
    }
}

struct NewGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var achievementService: AchievementService
    @State private var selectedType: AchievementType = .totalSessions
    @State private var targetValue: String = ""
    @State private var duration: Int = 7
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(AchievementType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Target")) {
                    TextField("Target Value", text: $targetValue)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Duration")) {
                    Picker("Days", selection: $duration) {
                        Text("7 days").tag(7)
                        Text("14 days").tag(14)
                        Text("30 days").tag(30)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        if let value = Int(targetValue) {
                            achievementService.createGoal(
                                type: selectedType,
                                targetValue: value,
                                duration: duration
                            )
                            dismiss()
                        }
                    }
                    .disabled(targetValue.isEmpty)
                }
            }
        }
    }
} 