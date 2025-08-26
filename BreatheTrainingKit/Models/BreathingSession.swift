import Foundation

struct BreathingSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let completedCycles: Int
    let mode: BreathingMode
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 