import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var historyService: HistoryService
    @State private var showingClearConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 16) {
                        StatCard(title: "Total Sessions", value: "\(historyService.totalSessions)")
                        StatCard(title: "Total Time", value: formatTime(historyService.totalDuration))
                        StatCard(title: "Total Cycles", value: "\(historyService.totalCycles)")
                        StatCard(title: "Avg. Session", value: formatTime(historyService.averageSessionDuration))
                    }
                    .padding(.vertical)
                }
                
                Section(header: Text("Recent Sessions")) {
                    if historyService.sessions.isEmpty {
                        Text("No sessions yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(historyService.sessions) { session in
                            SessionRow(session: session)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingClearConfirmation = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Clear History", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    historyService.clearHistory()
                }
            } message: {
                Text("Are you sure you want to clear all session history? This action cannot be undone.")
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SessionRow: View {
    let session: BreathingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text(session.mode.rawValue)
                    .font(.headline)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(session.formattedDuration)
                        .font(.subheadline)
                    Text("\(session.completedCycles) cycles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
} 