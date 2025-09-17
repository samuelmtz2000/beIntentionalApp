import SwiftUI

struct MarathonRecoveryView: View {
    @ObservedObject var game: GameStateManager
    var onRequestHealthAccess: () -> Void

    var progress: Double {
        let total = max(1, game.recoveryTarget)
        return min(1.0, Double(game.recoveryDistance) / Double(total))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🏃 Marathon Recovery").font(.title2).bold()
            ProgressView(value: progress)
                .tint(.orange)
            HStack {
                Text(String(format: "%.1f / %.1f km", Double(game.recoveryDistance)/1000.0, Double(game.recoveryTarget)/1000.0))
                Spacer()
                Text("\(Int(progress * 100))%")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            Button("Enable Health Access") { onRequestHealthAccess() }
                .buttonStyle(SecondaryButtonStyle())
        }
        .padding(24)
    }
}

