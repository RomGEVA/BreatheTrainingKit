import Foundation
import Combine

class CustomPatternService: ObservableObject {
    @Published var customPatterns: [CustomBreathingPattern] = []
    @Published var favoritePatterns: [CustomBreathingPattern] = []
    
    private let userDefaults = UserDefaults.standard
    private let customPatternsKey = "customBreathingPatterns"
    
    init() {
        loadCustomPatterns()
        updateFavoritePatterns()
    }
    
    // MARK: - CRUD Operations
    
    func addCustomPattern(_ pattern: CustomBreathingPattern) {
        customPatterns.append(pattern)
        saveCustomPatterns()
        updateFavoritePatterns()
    }
    
    func updateCustomPattern(_ pattern: CustomBreathingPattern) {
        if let index = customPatterns.firstIndex(where: { $0.id == pattern.id }) {
            customPatterns[index] = pattern
            saveCustomPatterns()
            updateFavoritePatterns()
        }
    }
    
    func deleteCustomPattern(_ pattern: CustomBreathingPattern) {
        customPatterns.removeAll { $0.id == pattern.id }
        saveCustomPatterns()
        updateFavoritePatterns()
    }
    
    func toggleFavorite(_ pattern: CustomBreathingPattern) {
        if let index = customPatterns.firstIndex(where: { $0.id == pattern.id }) {
            customPatterns[index].isFavorite.toggle()
            saveCustomPatterns()
            updateFavoritePatterns()
        }
    }
    
    // MARK: - Predefined Patterns
    
    func addPredefinedPatterns() {
        let predefinedPatterns = [
            CustomBreathingPattern(
                name: "4-7-8 Sleep",
                description: "Perfect for falling asleep quickly",
                inhale: 4,
                hold1: 7,
                exhale: 8,
                hold2: 0,
                cycles: 4
            ),
            CustomBreathingPattern(
                name: "Box Breathing",
                description: "Military technique for focus and calm",
                inhale: 4,
                hold1: 4,
                exhale: 4,
                hold2: 4,
                cycles: 5
            ),
            CustomBreathingPattern(
                name: "Triangle Breathing",
                description: "Simple pattern for beginners",
                inhale: 3,
                hold1: 3,
                exhale: 3,
                hold2: 0,
                cycles: 10
            ),
            CustomBreathingPattern(
                name: "Energy Boost",
                description: "Quick energizing breathing",
                inhale: 2,
                hold1: 1,
                exhale: 2,
                hold2: 0,
                cycles: 15
            ),
            CustomBreathingPattern(
                name: "Deep Relaxation",
                description: "Slow breathing for deep relaxation",
                inhale: 6,
                hold1: 8,
                exhale: 10,
                hold2: 2,
                cycles: 3
            )
        ]
        
        for pattern in predefinedPatterns {
            if !customPatterns.contains(where: { $0.name == pattern.name }) {
                customPatterns.append(pattern)
            }
        }
        
        saveCustomPatterns()
        updateFavoritePatterns()
    }
    
    // MARK: - Search and Filter
    
    func searchPatterns(query: String) -> [CustomBreathingPattern] {
        if query.isEmpty {
            return customPatterns
        }
        
        return customPatterns.filter { pattern in
            pattern.name.localizedCaseInsensitiveContains(query) ||
            pattern.description.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getPatternsByDuration(minDuration: TimeInterval, maxDuration: TimeInterval) -> [CustomBreathingPattern] {
        return customPatterns.filter { pattern in
            let duration = pattern.totalSessionTime
            return duration >= minDuration && duration <= maxDuration
        }
    }
    
    func getPatternsByDifficulty() -> [CustomBreathingPattern] {
        return customPatterns.sorted { pattern1, pattern2 in
            let difficulty1 = calculateDifficulty(pattern1)
            let difficulty2 = calculateDifficulty(pattern2)
            return difficulty1 < difficulty2
        }
    }
    
    private func calculateDifficulty(_ pattern: CustomBreathingPattern) -> Double {
        let totalTime = pattern.totalDuration
        let cycles = Double(pattern.cycles)
        let complexity = (pattern.hold1Duration + pattern.hold2Duration) / totalTime
        
        return (totalTime * cycles * (1 + complexity)) / 100
    }
    
    // MARK: - Private Methods
    
    private func updateFavoritePatterns() {
        favoritePatterns = customPatterns.filter { $0.isFavorite }
    }
    
    private func saveCustomPatterns() {
        if let encoded = try? JSONEncoder().encode(customPatterns) {
            userDefaults.set(encoded, forKey: customPatternsKey)
        }
    }
    
    private func loadCustomPatterns() {
        if let data = userDefaults.data(forKey: customPatternsKey),
           let decoded = try? JSONDecoder().decode([CustomBreathingPattern].self, from: data) {
            customPatterns = decoded
        } else {
            // Load predefined patterns if no custom patterns exist
            addPredefinedPatterns()
        }
    }
}

// MARK: - Extensions

extension CustomBreathingPattern {
    var difficultyLevel: String {
        let difficulty = calculateDifficulty()
        
        switch difficulty {
        case 0..<50:
            return "Beginner"
        case 50..<100:
            return "Intermediate"
        case 100..<200:
            return "Advanced"
        default:
            return "Expert"
        }
    }
    
    private func calculateDifficulty() -> Double {
        let totalTime = totalDuration
        let cycles = Double(self.cycles)
        let complexity = (hold1Duration + hold2Duration) / totalTime
        
        return (totalTime * cycles * (1 + complexity)) / 100
    }
    
    var estimatedCalories: Int {
        // Rough estimate: 1 calorie per minute of breathing exercise
        return Int(totalSessionTime / 60)
    }
    
    var tags: [String] {
        var tags: [String] = []
        
        if inhaleDuration > 6 { tags.append("Deep Breathing") }
        if hold1Duration > 5 { tags.append("Hold Focus") }
        if exhaleDuration > 8 { tags.append("Long Exhale") }
        if cycles > 10 { tags.append("Endurance") }
        if totalSessionTime > 600 { tags.append("Long Session") }
        
        return tags
    }
}
