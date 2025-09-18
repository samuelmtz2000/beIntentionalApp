import SwiftUI

struct RecoveryCompletionModal: View {
    var onDone: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text("🎉 Recovery Complete!")
                .font(.title)
                .bold()
            Text("Your health has been restored and the game is active again.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Continue") { onDone() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }
}

