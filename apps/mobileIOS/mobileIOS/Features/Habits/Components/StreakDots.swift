//
//  StreakDots.swift
//  mobileIOS
//

import SwiftUI

struct GoodHistoryDotsView: View {
    let history: [StreaksViewModel.HabitHistoryItem]
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(history.suffix(7)).indices, id: \.self) { i in
                let item = Array(history.suffix(7))[i]
                dotGood(status: item.status)
            }
        }
        .contentShape(Rectangle())
    }

    private func dotGood(status: String) -> some View {
        Group {
            if status == "done" {
                Circle().fill(Color.green).frame(width: 8, height: 8)
            } else if status == "inactive" {
                Circle().fill(Color.gray.opacity(0.3)).frame(width: 8, height: 8)
            } else {
                Circle().stroke(Color.gray, lineWidth: 1).frame(width: 8, height: 8)
            }
        }
    }
}

struct BadHistoryDotsView: View {
    let history: [StreaksViewModel.HabitHistoryItem]
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(history.suffix(7)).indices, id: \.self) { i in
                let item = Array(history.suffix(7))[i]
                dotBad(status: item.status)
            }
        }
        .contentShape(Rectangle())
    }

    private func dotBad(status: String) -> some View {
        Group {
            if status == "occurred" {
                Circle().fill(Color.red).frame(width: 8, height: 8)
            } else if status == "forgiven" {
                Circle().fill(Color.yellow).frame(width: 8, height: 8)
            } else {
                Circle().fill(Color.green).frame(width: 8, height: 8)
            }
        }
    }
}

