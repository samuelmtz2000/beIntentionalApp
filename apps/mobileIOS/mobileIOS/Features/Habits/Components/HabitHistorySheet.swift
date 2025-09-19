//
//  HabitHistorySheet.swift
//  mobileIOS
//

import SwiftUI

struct HabitHistorySheet: View {
    let title: String
    let habitId: String
    let type: String // "good" | "bad"
    @ObservedObject var streaks: StreaksViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var items: [StreaksViewModel.HabitHistoryItem] = []

    private var current: Int { streaks.perHabit[habitId]?.currentCount ?? 0 }
    private var longest: Int { streaks.perHabit[habitId]?.longestCount ?? 0 }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    if type == "good" {
                        Label("\(current)", systemImage: "flame.fill").foregroundStyle(.orange)
                    } else {
                        Label("\(current)", systemImage: "shield.fill").foregroundStyle(.green)
                    }
                    Text("Longest: \(longest)").dsFont(.caption).foregroundStyle(.secondary)
                }

                legend

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(12), spacing: 6), count: 10), spacing: 6) {
                        ForEach(items.indices, id: \.self) { i in
                            let s = items[i].status
                            if type == "good" {
                                dotGood(status: s)
                            } else {
                                dotBad(status: s)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .navigationTitle(title)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .task {
                await streaks.loadHistoryIfNeeded(habitId: habitId, type: type, days: 30, force: true)
                if type == "good" { items = streaks.goodHistory[habitId] ?? [] } else { items = streaks.badHistory[habitId] ?? [] }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 12) {
            if type == "good" {
                HStack(spacing: 6) { Circle().fill(Color.green).frame(width: 8,height: 8); Text("Done").dsFont(.caption) }
                HStack(spacing: 6) { Circle().stroke(Color.gray, lineWidth: 1).frame(width: 8,height: 8); Text("Miss").dsFont(.caption) }
                HStack(spacing: 6) { Circle().fill(Color.gray.opacity(0.3)).frame(width: 8,height: 8); Text("Inactive").dsFont(.caption) }
            } else {
                HStack(spacing: 6) { Circle().fill(Color.green).frame(width: 8,height: 8); Text("Clean").dsFont(.caption) }
                HStack(spacing: 6) { Circle().fill(Color.yellow).frame(width: 8,height: 8); Text("Forgiven").dsFont(.caption) }
                HStack(spacing: 6) { Circle().fill(Color.red).frame(width: 8,height: 8); Text("Occurred").dsFont(.caption) }
            }
        }
    }

    private func dotGood(status: String) -> some View {
        Group {
            if status == "done" {
                Circle().fill(Color.green).frame(width: 10, height: 10)
            } else if status == "inactive" {
                Circle().fill(Color.gray.opacity(0.3)).frame(width: 10, height: 10)
            } else {
                Circle().stroke(Color.gray, lineWidth: 1).frame(width: 10, height: 10)
            }
        }
    }

    private func dotBad(status: String) -> some View {
        Group {
            if status == "occurred" {
                Circle().fill(Color.red).frame(width: 10, height: 10)
            } else if status == "forgiven" {
                Circle().fill(Color.yellow).frame(width: 10, height: 10)
            } else {
                Circle().fill(Color.green).frame(width: 10, height: 10)
            }
        }
    }
}

