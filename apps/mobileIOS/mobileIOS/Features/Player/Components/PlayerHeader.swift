//
//  PlayerHeader.swift
//  mobileIOS
//
//  Player header component showing level, XP, life, coins, and streak
//

import SwiftUI
import Combine

struct PlayerHeader: View {
    let profile: Profile?
    var onLogToday: () -> Void = {}
    var onOpenStore: () -> Void = {}
    
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var app: AppModel
    @State private var celebrate = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                if let p = profile {
                    // Level and XP Progress
                    VStack(alignment: .leading, spacing: 4) {
                        levelBadge(level: p.level)
                        xpProgress(profile: p)
                        todaysProgress()
                    }
                    
                    Spacer()
                    
                    // Stats (right column, top→bottom): Heart, Coins, Streak
                    VStack(alignment: .trailing, spacing: 6) {
                        lifeRow(profile: p)
                        coinsRow(profile: p)
                        streakIndicator()
                    }
                } else {
                    // No loader: keep header slim until data arrives
                    Rectangle().fill(Color.clear).frame(height: 8)
                }
            }

            // Removed full-width streak card per latest guidance
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .task { await app.streaks.refreshGeneralToday() }
        .onReceive(NotificationCenter.default.publisher(for: .streaksDidChange)) { _ in
            Task { await app.streaks.refreshGeneralToday() }
        }
        // No explicit loader timing; header stays minimal without spinners
    }
    
    // MARK: - Subviews
    
    private func levelBadge(level: Int) -> some View {
        HStack {
            Text("Lvl \(level)")
                .bold()
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.blue.opacity(0.15)))
        }
    }
    
    private func xpProgress(profile: Profile) -> some View {
        let need = PlayerHelper.xpNeeded(
            level: profile.level,
            base: profile.xpPerLevel,
            curve: profile.config?.levelCurve ?? "linear",
            multiplier: profile.config?.levelMultiplier ?? 1.5
        )
        
        return DSProgressBar(
            value: Double(profile.xp),
            total: Double(max(need, 1)),
            label: "XP → \(profile.xp)/\(need)"
        )
    }
    
    private func statsRow(profile: Profile) -> some View {
        VStack(alignment: .trailing, spacing: 0) { EmptyView() }
    }

    private func lifeRow(profile: Profile) -> some View {
        Group {
            if profile.life <= 0 {
                Text("💀").font(.callout)
            } else {
                Label("\(max(profile.life, 0))", systemImage: "heart.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
            }
        }
        .labelStyle(.titleAndIcon)
    }

    private func coinsRow(profile: Profile) -> some View {
        Label("\(profile.coins)", systemImage: "creditcard")
            .font(.callout)
            .labelStyle(.titleAndIcon)
    }

    private func streakIndicator() -> some View {
        return Group {
            if let today = app.streaks.generalToday {
                Label("\(app.streaks.generalCurrent)", systemImage: today.hasUnforgivenBad ? "flame.circle" : "flame")
                    .foregroundStyle(today.hasUnforgivenBad ? .red : .orange)
                    .font(.callout)
                    .scaleEffect(celebrate ? 1.25 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: celebrate)
                    .onChange(of: today.daySuccess) { _, newVal in
                        if newVal == true {
                            celebrate = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                celebrate = false
                            }
                        }
                    }
                    .accessibilityLabel("General streak \(app.streaks.generalCurrent)")
            } else {
                Label("Streak —", systemImage: "flame")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
    }

    // Removed full-width general streak card

    private func todaysProgress() -> some View {
        return Group {
            if let today = app.streaks.generalToday {
                let total = max(1, today.totalActiveGood)
                let value = min(total, max(0, today.completedGood))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(today.completedGood)/\(today.totalActiveGood)")
                            .dsFont(.caption)
                            .foregroundStyle(.green)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(today.totalBadCount ?? (today.hasUnforgivenBad ? 1 : 0))")
                            .dsFont(.caption)
                            .foregroundStyle(.red)
                    }
                    DSProgressBar(
                        value: Double(value),
                        total: Double(total),
                        label: nil,
                        showPercentage: true,
                        tintColor: (today.unforgivenBadCount ?? 0) > 0 ? Color.red : .green
                    )
                }
            }
        }
    }

    // using @StateObject streaks; no ensureVM
}

// MARK: - Player Helper

enum PlayerHelper {
    static func xpNeeded(level: Int, base: Int, curve: String, multiplier: Double) -> Int {
        if curve == "exp" {
            let m = max(1.0, multiplier)
            let powv = pow(m, Double(max(0, level - 1)))
            return max(1, Int(floor(Double(base) * powv)))
        } else {
            return max(1, base)
        }
    }
    
    static func areaXpNeeded(level: Int, base: Int, curve: String, multiplier: Double) -> Int {
        return xpNeeded(level: level, base: base, curve: curve, multiplier: multiplier)
    }
}
