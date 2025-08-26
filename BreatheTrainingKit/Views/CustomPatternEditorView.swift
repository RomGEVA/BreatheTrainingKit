import SwiftUI

struct CustomPatternEditorView: View {
    let pattern: CustomBreathingPattern?
    let onSave: (CustomBreathingPattern) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var inhaleDuration: Double = 4
    @State private var hold1Duration: Double = 4
    @State private var exhaleDuration: Double = 4
    @State private var hold2Duration: Double = 4
    @State private var cycles: Int = 5
    @State private var isFavorite: Bool = false
    
    @State private var showingPreview = false
    @State private var showingDeleteAlert = false
    
    private var isEditing: Bool {
        pattern != nil
    }
    
    private var totalDuration: TimeInterval {
        inhaleDuration + hold1Duration + exhaleDuration + hold2Duration
    }
    
    private var totalSessionTime: TimeInterval {
        totalDuration * Double(cycles)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Basic Information
                Section(header: Text("Basic Information")) {
                    TextField("Pattern Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // MARK: - Breathing Phases
                Section(header: Text("Breathing Phases")) {
                    VStack(alignment: .leading, spacing: 12) {
                        DurationSlider(
                            title: "Inhale",
                            icon: "lungs.fill",
                            value: $inhaleDuration,
                            range: 1...20,
                            color: .blue
                        )
                        
                        DurationSlider(
                            title: "Hold (Inhale)",
                            icon: "pause.fill",
                            value: $hold1Duration,
                            range: 0...20,
                            color: .green
                        )
                        
                        DurationSlider(
                            title: "Exhale",
                            icon: "lungs",
                            value: $exhaleDuration,
                            range: 1...20,
                            color: .orange
                        )
                        
                        DurationSlider(
                            title: "Hold (Exhale)",
                            icon: "pause.fill",
                            value: $hold2Duration,
                            range: 0...20,
                            color: .purple
                        )
                    }
                }
                
                // MARK: - Session Settings
                Section(header: Text("Session Settings")) {
                    Stepper("Cycles: \(cycles)", value: $cycles, in: 1...50)
                    
                    HStack {
                        Label("Total Duration", systemImage: "clock")
                        Spacer()
                        Text(formatTime(totalDuration))
                            .font(.headline)
                    }
                    
                    HStack {
                        Label("Session Time", systemImage: "timer")
                        Spacer()
                        Text(formatTime(totalSessionTime))
                            .font(.headline)
                    }
                }
                
                // MARK: - Preview
                Section(header: Text("Preview")) {
                    Button(action: { showingPreview = true }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Preview Pattern")
                        }
                    }
                    
                    if let difficulty = calculateDifficulty() {
                        HStack {
                            Label("Difficulty", systemImage: "target")
                            Spacer()
                            Text(difficulty)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(difficultyColor(for: difficulty))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    
                    HStack {
                        Label("Estimated Calories", systemImage: "flame")
                        Spacer()
                        Text("\(Int(totalSessionTime / 60)) cal")
                            .font(.caption)
                    }
                }
                
                // MARK: - Options
                Section(header: Text("Options")) {
                    Toggle("Add to Favorites", isOn: $isFavorite)
                }
                
                // MARK: - Quick Templates
                Section(header: Text("Quick Templates")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        TemplateButton(title: "4-7-8", description: "Sleep") {
                            applyTemplate(inhale: 4, hold1: 7, exhale: 8, hold2: 0, cycles: 4)
                        }
                        
                        TemplateButton(title: "Box", description: "Focus") {
                            applyTemplate(inhale: 4, hold1: 4, exhale: 4, hold2: 4, cycles: 5)
                        }
                        
                        TemplateButton(title: "Triangle", description: "Simple") {
                            applyTemplate(inhale: 3, hold1: 3, exhale: 3, hold2: 0, cycles: 10)
                        }
                        
                        TemplateButton(title: "Energy", description: "Boost") {
                            applyTemplate(inhale: 2, hold1: 1, exhale: 2, hold2: 0, cycles: 15)
                        }
                    }
                }
                
                if isEditing {
                    Section {
                        Button("Delete Pattern", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Pattern" : "New Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePattern()
                    }
                    .disabled(name.isEmpty || description.isEmpty)
                }
            }
            .onAppear {
                loadPattern()
            }
            .sheet(isPresented: $showingPreview) {
                PatternPreviewView(
                    name: name,
                    inhaleDuration: inhaleDuration,
                    hold1Duration: hold1Duration,
                    exhaleDuration: exhaleDuration,
                    hold2Duration: hold2Duration,
                    cycles: cycles
                )
            }
            .alert("Delete Pattern", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    // Handle deletion through parent view
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this pattern? This action cannot be undone.")
            }
        }
    }
    
    private func loadPattern() {
        guard let pattern = pattern else { return }
        
        name = pattern.name
        description = pattern.description
        inhaleDuration = pattern.inhaleDuration
        hold1Duration = pattern.hold1Duration
        exhaleDuration = pattern.exhaleDuration
        hold2Duration = pattern.hold2Duration
        cycles = pattern.cycles
        isFavorite = pattern.isFavorite
    }
    
    private func savePattern() {
        let newPattern = CustomBreathingPattern(
            name: name,
            description: description,
            inhale: inhaleDuration,
            hold1: hold1Duration,
            exhale: exhaleDuration,
            hold2: hold2Duration,
            cycles: cycles
        )
        
        var savedPattern = newPattern
        savedPattern.isFavorite = isFavorite
        
        if let existingPattern = pattern {
            savedPattern.id = existingPattern.id
            savedPattern.createdAt = existingPattern.createdAt
        }
        
        onSave(savedPattern)
        dismiss()
    }
    
    private func applyTemplate(inhale: Double, hold1: Double, exhale: Double, hold2: Double, cycles: Int) {
        inhaleDuration = inhale
        self.hold1Duration = hold1
        exhaleDuration = exhale
        self.hold2Duration = hold2
        self.cycles = cycles
    }
    
    private func calculateDifficulty() -> String? {
        let difficulty = (totalDuration * Double(cycles) * (1 + (hold1Duration + hold2Duration) / totalDuration)) / 100
        
        switch difficulty {
        case 0..<50: return "Beginner"
        case 50..<100: return "Intermediate"
        case 100..<200: return "Advanced"
        default: return "Expert"
        }
    }
    
    private func difficultyColor(for difficulty: String) -> Color {
        switch difficulty {
        case "Beginner": return .green
        case "Intermediate": return .blue
        case "Advanced": return .orange
        case "Expert": return .red
        default: return .gray
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Duration Slider

struct DurationSlider: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                Spacer()
                Text("\(Int(value))s")
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            Slider(value: $value, in: range, step: 1)
                .accentColor(color)
        }
    }
}

// MARK: - Template Button

struct TemplateButton: View {
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
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
}

// MARK: - Pattern Preview View

struct PatternPreviewView: View {
    let name: String
    let inhaleDuration: Double
    let hold1Duration: Double
    let exhaleDuration: Double
    let hold2Duration: Double
    let cycles: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentPhase: BreathPhase = .inhale
    @State private var timeRemaining: TimeInterval = 0
    @State private var currentCycle = 1
    @State private var isRunning = false
    
    private var totalDuration: TimeInterval {
        inhaleDuration + hold1Duration + exhaleDuration + hold2Duration
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text(name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Cycle \(currentCycle) of \(cycles)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Breathing Circle
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 150, height: 150)
                        .scaleEffect(isRunning ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 2), value: isRunning)
                    
                    VStack(spacing: 8) {
                        Text(currentPhase.rawValue)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("\(Int(timeRemaining))s")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Phase Info
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        PhaseInfo(phase: "Inhale", duration: inhaleDuration, color: .blue)
                        PhaseInfo(phase: "Hold", duration: hold1Duration, color: .green)
                        PhaseInfo(phase: "Exhale", duration: exhaleDuration, color: .orange)
                        PhaseInfo(phase: "Pause", duration: hold2Duration, color: .purple)
                    }
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 20) {
                    Button(action: resetPreview) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .padding()
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    
                    Button(action: togglePreview) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
            .navigationTitle("Preview")
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
    
    private func togglePreview() {
        if isRunning {
            stopPreview()
        } else {
            startPreview()
        }
    }
    
    private func startPreview() {
        isRunning = true
        currentPhase = .inhale
        timeRemaining = inhaleDuration
        currentCycle = 1
        startTimer()
    }
    
    private func stopPreview() {
        isRunning = false
        resetPreview()
    }
    
    private func resetPreview() {
        currentPhase = .inhale
        timeRemaining = inhaleDuration
        currentCycle = 1
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard isRunning else {
                timer.invalidate()
                return
            }
            
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                moveToNextPhase()
            }
        }
    }
    
    private func moveToNextPhase() {
        switch currentPhase {
        case .inhale:
            currentPhase = .hold1
            timeRemaining = hold1Duration
        case .hold1:
            currentPhase = .exhale
            timeRemaining = exhaleDuration
        case .exhale:
            currentPhase = .hold2
            timeRemaining = hold2Duration
        case .hold2:
            if currentCycle < cycles {
                currentCycle += 1
                currentPhase = .inhale
                timeRemaining = inhaleDuration
            } else {
                stopPreview()
            }
        }
    }
}

struct PhaseInfo: View {
    let phase: String
    let duration: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(phase)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(duration))s")
                .font(.headline)
                .foregroundColor(color)
        }
    }
}
