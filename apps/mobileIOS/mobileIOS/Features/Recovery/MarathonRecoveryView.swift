import SwiftUI

struct MarathonRecoveryView: View {
    @ObservedObject var game: GameStateManager
    @Binding var isHealthAccessConfigured: Bool
    var onRequestHealthAccess: () -> Void
    var onUpdateProgress: () -> Void

    var progress: Double {
        let total = max(1, game.recoveryTarget)
        return min(1.0, Double(game.recoveryDistance) / Double(total))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🏃 Running Challenge").font(.title2).bold()
            if let started = game.recoveryStartedAt ?? game.gameOverAt {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("Started: \(format(date: started))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: progress)
                .tint(.orange)
            HStack {
                Text(String(format: "%.1f / %.1f km", Double(game.recoveryDistance)/1000.0, Double(game.recoveryTarget)/1000.0))
                Spacer()
                Text("\(Int(progress * 100))%")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            if isHealthAccessConfigured {
                Button("Update Progress") { onUpdateProgress() }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Enable Health Access") { onRequestHealthAccess() }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(24)
    }

    private func format(date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }
}
