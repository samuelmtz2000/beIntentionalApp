//
//  PlayerHeader.swift
//  mobileIOS
//
//  Player header component showing level, XP, life, coins, and streak
//

import SwiftUI

struct PlayerHeader: View {
    let profile: Profile?
    var onLogToday: () -> Void = {}
    var onOpenStore: () -> Void = {}
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                if let p = profile {
                    // Level and XP Progress
                    VStack(alignment: .leading, spacing: 4) {
                        levelBadge(level: p.level)
                        xpProgress(profile: p)
                    }
                    
                    Spacer()
                    
                    // Stats (Life, Coins, Streak)
                    VStack(alignment: .trailing, spacing: 4) {
                        statsRow(profile: p)
                        streakIndicator()
                    }
                } else {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
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
        HStack(spacing: 12) {
            Label("\(profile.life)/100", systemImage: "heart.fill")
                .foregroundStyle(.red)
                .font(.callout)
            
            Label("\(profile.coins)", systemImage: "creditcard")
                .font(.callout)
        }
        .labelStyle(.titleAndIcon)
    }
    
    private func streakIndicator() -> some View {
        Label("Streak N/A", systemImage: "flame")
            .foregroundStyle(.orange)
            .font(.caption)
    }
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
