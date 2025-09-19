//
//  MainNavigationBar.swift
//  mobileIOS
//
//  Reusable navigation bar with animated pills for section switching
//

import SwiftUI

enum NavigationSection: String, CaseIterable {
    case player = "Player"
    case habits = "Habits"
    case areas = "Areas"
    case store = "Store"
    case archive = "Archive"
    case config = "Config"
    
    var icon: String {
        switch self {
        case .player: return "person.crop.circle"
        case .habits: return "checkmark.circle"
        case .areas: return "square.grid.2x2"
        case .store: return "cart"
        case .archive: return "archivebox"
        case .config: return "gearshape"
        }
    }
    
    var isNavigable: Bool {
        self != .config
    }
}

struct MainNavigationBar: View {
    @Binding var selected: NavigationSection
    var onConfig: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(NavigationSection.allCases, id: \.self) { section in
                    DSNavigationPill(
                        title: section.rawValue,
                        icon: section.icon,
                        isSelected: selected == section,
                        action: {
                            handleSelection(section)
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
        .background(
            Color.clear
                .contentShape(Rectangle())
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    handleSwipe(translation: value.translation.width)
                }
        )
    }
    
    // MARK: - Actions
    
    private func handleSelection(_ section: NavigationSection) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if section == .config {
                onConfig?()
            } else {
                selected = section
            }
        }
    }
    
    private func handleSwipe(translation: CGFloat) {
        let navigableSections = NavigationSection.allCases.filter { $0.isNavigable }
        guard let currentIndex = navigableSections.firstIndex(of: selected) else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if translation < -30 {
                // Swipe left - go to next
                let nextIndex = (currentIndex + 1) % navigableSections.count
                selected = navigableSections[nextIndex]
            } else if translation > 30 {
                // Swipe right - go to previous
                let previousIndex = currentIndex == 0 ? navigableSections.count - 1 : currentIndex - 1
                selected = navigableSections[previousIndex]
            }
        }
    }
}

// MARK: - Header Container

struct NavigationHeaderContainer: View {
    @ObservedObject var profileVM: ProfileViewModel
    @ObservedObject var game: GameStateManager
    @Binding var selected: NavigationSection
    var onConfig: (() -> Void)? = nil
    var onOpenRecovery: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(spacing: 8) {
            PlayerHeader(
                profile: profileVM.profile,
                onLogToday: { selected = .habits },
                onOpenStore: { selected = .store }
            )
            if let openRecovery = onOpenRecovery {
                // Derive Game Over based on life (same approach as skull in PlayerHeader)
                let isGameOverUI = (profileVM.profile?.life ?? 0) <= 0 || game.state == .gameOver
                if isGameOverUI {
                    DSInfoBanner(
                        icon: "figure.run.circle.fill",
                        title: "Game Over",
                        message: "Bad habits are disabled until you complete recovery.",
                        actionTitle: "Details",
                        action: openRecovery
                    )
                    .padding(.horizontal, 12)
                } else if game.state == .recovery && game.recoveryDistance >= game.recoveryTarget {
                    DSInfoBanner(
                        icon: "figure.run.circle.fill",
                        title: "Recovery Complete",
                        message: "You reached the running challenge distance. Finalize to restore the game.",
                        actionTitle: "Details",
                        action: openRecovery
                    )
                    .padding(.horizontal, 12)
                }
            }
            
            MainNavigationBar(
                selected: $selected,
                onConfig: onConfig
            )
        }
        .background(DSTheme.colors(for: scheme).backgroundSecondary)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    handleHeaderSwipe(translation: value.translation.width)
                }
        )
    }
    
    private func handleHeaderSwipe(translation: CGFloat) {
        let navigableSections = NavigationSection.allCases.filter { $0.isNavigable }
        guard let currentIndex = navigableSections.firstIndex(of: selected) else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if translation < -30 {
                let nextIndex = (currentIndex + 1) % navigableSections.count
                selected = navigableSections[nextIndex]
            } else if translation > 30 {
                let previousIndex = currentIndex == 0 ? navigableSections.count - 1 : currentIndex - 1
                selected = navigableSections[previousIndex]
            }
        }
    }
}
