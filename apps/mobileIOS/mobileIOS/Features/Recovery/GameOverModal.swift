import SwiftUI

struct GameOverModal: View {
    var targetMeters: Int
    var onStartRecovery: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("💀 GAME OVER")
                .font(.title)
                .bold()
            Text("Your health has reached 0. To continue playing, complete the running challenge (\(String(format: "%.2f", Double(targetMeters)/1000.0)) km) by running or walking.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Start Running Challenge") { onStartRecovery() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }
}
