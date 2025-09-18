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
    let pieces: [ConfettiPiece]

    init(count: Int = 28) {
        let emojis = ["🎉","✨","🎊","💥","⭐️","🥳"]
        var arr: [ConfettiPiece] = []
        for _ in 0..<count {
            arr.append(ConfettiPiece(
                emoji: emojis.randomElement()!,
                x: CGFloat.random(in: -140...140),
                scale: CGFloat.random(in: 0.8...1.3),
                rotation: Double.random(in: -30...30),
                speed: Double.random(in: 0.6...1.2)
            ))
        }
        self.pieces = arr
    }
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(pieces) { p in
                        let duration = 3.0
                        let progress = (t * p.speed).truncatingRemainder(dividingBy: duration) / duration
                        let y = -40 + progress * (geo.size.height + 80)
                        let midX = geo.size.width / 2
                        Text(p.emoji)
                            .font(.system(size: 24))
                            .scaleEffect(p.scale)
                            .rotationEffect(.degrees(p.rotation * progress * 8))
                            .position(x: midX + p.x, y: y)
                            .opacity(progress < 0.95 ? 1 : 0)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
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
