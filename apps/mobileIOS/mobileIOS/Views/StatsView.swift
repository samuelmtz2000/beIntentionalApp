import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var profileVM: ProfileViewModel

    init() {
        let app = AppModel()
        _profileVM = StateObject(wrappedValue: ProfileViewModel(api: app.api))
    }

    var body: some View {
        NavigationStack {
            List {
                if let p = profileVM.profile {
                    Section("Overall") {
                        LabeledContent("Life", value: "\(p.life)")
                        LabeledContent("Coins", value: "\(p.coins)")
                        LabeledContent("Areas", value: "\(p.areas.count)")
                    }
                    Section("Per Area") {
                        ForEach(p.areas, id: \.areaId) { a in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack { Text(a.name).dsFont(.headerMD); Spacer(); Text("Lvl \(a.level)").dsFont(.caption) }
                                ProgressView(value: Double(a.xp), total: Double(a.xpPerLevel))
                                    .tint(.blue)
                            }
                        }
                    }
                } else {
                    Text("No profile yet. Pull to refresh.").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Stats")
            .refreshable { await profileVM.refresh() }
            .task { await profileVM.refresh() }
        }
    }
}
