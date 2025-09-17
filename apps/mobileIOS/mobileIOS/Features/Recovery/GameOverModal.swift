import SwiftUI

struct GameOverModal: View {
    var onStartRecovery: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("💀 GAME OVER")
                .font(.title)
                .bold()
            Text("Your health has reached 0. To continue playing, complete a marathon distance (42.195 km) by running or walking.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Start Recovery Challenge") { onStartRecovery() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }
}

