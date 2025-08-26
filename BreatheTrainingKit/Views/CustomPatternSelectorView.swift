import SwiftUI

struct CustomPatternSelectorView: View {
    @EnvironmentObject var customPatternService: CustomPatternService
    @EnvironmentObject var breathingViewModel: BreathingViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedFilter: PatternFilter = .all
    @State private var showingCreatePattern = false
    
    enum PatternFilter: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
    }
    
    var filteredPatterns: [CustomBreathingPattern] {
        var patterns = customPatternService.customPatterns
        
        // Apply search filter
        if !searchText.isEmpty {
            patterns = patterns.filter { pattern in
                pattern.name.localizedCaseInsensitiveContains(searchText) ||
                pattern.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply difficulty filter
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            patterns = patterns.filter { $0.isFavorite }
        case .beginner:
            patterns = patterns.filter { $0.difficultyLevel == "Beginner" }
        case .intermediate:
            patterns = patterns.filter { $0.difficultyLevel == "Intermediate" }
        case .advanced:
            patterns = patterns.filter { $0.difficultyLevel == "Advanced" }
        case .expert:
            patterns = patterns.filter { $0.difficultyLevel == "Expert" }
        }
        
        return patterns
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search patterns...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PatternFilter.allCases, id: \.self) { filter in
                                FilterPill(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter,
                                    action: { selectedFilter = filter }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Patterns List
                if filteredPatterns.isEmpty {
                    EmptyStateView(
                        icon: "lungs.fill",
                        title: "No Patterns Found",
                        message: searchText.isEmpty ? "Create your first custom breathing pattern" : "Try adjusting your search or filters"
                    )
                } else {
                    List(filteredPatterns) { pattern in
                        CustomPatternRow(pattern: pattern) {
                            selectPattern(pattern)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(pattern.isFavorite ? "Remove" : "Favorite") {
                                customPatternService.toggleFavorite(pattern)
                            }
                            .tint(pattern.isFavorite ? .red : .yellow)
                            
                            Button("Edit") {
                                // Handle edit
                            }
                            .tint(.blue)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Custom Patterns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        showingCreatePattern = true
                    }
                }
            }
            .sheet(isPresented: $showingCreatePattern) {
                CustomPatternEditorView(pattern: nil) { pattern in
                    customPatternService.addCustomPattern(pattern)
                }
            }
        }
    }
    
    private func selectPattern(_ pattern: CustomBreathingPattern) {
        breathingViewModel.selectCustomPattern(pattern)
        dismiss()
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Custom Pattern Row (Enhanced)

struct CustomPatternRow: View {
    let pattern: CustomBreathingPattern
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with name and favorite status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pattern.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(pattern.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    if pattern.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                }
                
                // Pattern details
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTime(pattern.totalDuration))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cycles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(pattern.cycles)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTime(pattern.totalSessionTime))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Difficulty badge
                    Text(pattern.difficultyLevel)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pattern.difficultyLevel.difficultyColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Tags
                if !pattern.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(pattern.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.secondary)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    CustomPatternSelectorView()
        .environmentObject(CustomPatternService())
        .environmentObject(BreathingViewModel())
}
