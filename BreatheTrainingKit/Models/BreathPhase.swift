import Foundation

enum BreathPhase: String, CaseIterable {
    case inhale = "Inhale"
    case hold1 = "Hold"
    case exhale = "Exhale"
    case hold2 = "Pause"
}

enum BreathingMode: String, CaseIterable, Codable {
    case box = "Box Breathing"
    case relax = "Relax"
    
    var phaseDurations: [BreathPhase: TimeInterval] {
        switch self {
        case .box:
            return [
                .inhale: 4,
                .hold1: 4,
                .exhale: 4,
                .hold2: 4
            ]
        case .relax:
            return [
                .inhale: 4,
                .hold1: 7,
                .exhale: 8,
                .hold2: 0
            ]
        }
    }
    
    var totalDuration: TimeInterval {
        phaseDurations.values.reduce(0, +)
    }
}


// ... 
 