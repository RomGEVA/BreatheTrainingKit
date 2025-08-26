//
//  StartView.swift
//  BreatheTrainingKit
//
//  Created by Роман Главацкий on 26.08.2025.
//

import SwiftUI

private let sharedHistoryService = HistoryService()
private let sharedAchievementService = AchievementService(historyService: sharedHistoryService)
private let sharedCustomPatternService = CustomPatternService()
private let sharedGoalService = GoalService()

struct StartView: View {
    @StateObject private var historyService = sharedHistoryService
    @StateObject private var achievementService = sharedAchievementService
    @StateObject private var customPatternService = sharedCustomPatternService
    @StateObject private var goalService = sharedGoalService
    @StateObject private var breathingViewModel = BreathingViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some View {
        if hasSeenOnboarding {
            ContentView()
                .environmentObject(historyService)
                .environmentObject(achievementService)
                .environmentObject(customPatternService)
                .environmentObject(goalService)
                .environmentObject(breathingViewModel)
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    StartView()
}
