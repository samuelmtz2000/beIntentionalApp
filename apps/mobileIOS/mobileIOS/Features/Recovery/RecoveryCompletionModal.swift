import SwiftUI

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let emoji: String
    let x: CGFloat
    let scale: CGFloat
    let rotation: Double
    let speed: Double
}

private struct ConfettiView: View {
    @State private var time: Double = 0
    let pieces: [ConfettiPiece]
    
    init(count: Int = 24) {
        let emojis = ["🎉","✨","🎊","💥","⭐️","🥳"]
        var arr: [ConfettiPiece] = []
        for _ in 0..<count {
            arr.append(ConfettiPiece(
                emoji: emojis.randomElement()!,
                x: CGFloat.random(in: -140...140),
                scale: CGFloat.random(in: 0.8...1.3),
                rotation: Double.random(in: -30...30),
                speed: Double.random(in: 0.7...1.3)
            ))
        }
        self.pieces = arr
    }
    
    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(pieces) { p in
                    let progress = (t * p.speed).truncatingRemainder(dividingBy: 3.0) / 3.0
                    let y = -200 + progress * 480
                    Text(p.emoji)
                        .font(.system(size: 24))
                        .scaleEffect(p.scale)
                        .rotationEffect(.degrees(p.rotation * progress * 6))
                        .position(x: 180 + p.x, y: y)
                        .opacity(progress < 0.95 ? 1 : 0)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct RecoveryCompletionModal: View {
    var onDone: () -> Void
    var body: some View {
        ZStack {
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

            ConfettiView()
        }
    }
}
