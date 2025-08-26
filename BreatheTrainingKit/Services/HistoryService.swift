import Foundation

class HistoryService: ObservableObject {
    @Published private(set) var sessions: [BreathingSession] = []
    private let maxSessions = 100
    
    init() {
        loadSessions()
    }
    
    func addSession(_ session: BreathingSession) {
        print("addSession called: \(session)")
        sessions.insert(session, at: 0)
        if sessions.count > maxSessions {
            sessions.removeLast()
        }
        saveSessions()
        print("sessions now: \(sessions.count)")
    }
    
    func clearHistory() {
        sessions.removeAll()
        saveSessions()
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "breathing_sessions")
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "breathing_sessions"),
           let decoded = try? JSONDecoder().decode([BreathingSession].self, from: data) {
            sessions = decoded
        }
    }
    
    var totalSessions: Int {
        sessions.count
    }
    
    var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    var totalCycles: Int {
        sessions.reduce(0) { $0 + $1.completedCycles }
    }
    
    var averageSessionDuration: TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        return totalDuration / Double(sessions.count)
    }
} 