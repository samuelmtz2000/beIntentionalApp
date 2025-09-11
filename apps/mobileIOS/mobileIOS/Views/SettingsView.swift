import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppModel
    @State private var baseURLString: String = UserDefaults.standard.string(forKey: "API_BASE_URL") ?? "http://localhost:4000"
    @State private var showingSaved = false

    @Environment(\.colorScheme) private var scheme
    var body: some View {
        NavigationStack {
            Form {
                Section("Developer") {
                    TextField("API Base URL", text: $baseURLString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    Button("Save Base URL") { saveBaseURL() }
                }
                Section("About") {
                    LabeledContent("App", value: "HabitHero")
                    LabeledContent("Backend", value: baseURLString)
                }
            }
            .navigationTitle("Settings")
            .toolbarBackground(DSTheme.colors(for: scheme).backgroundSecondary, for: .navigationBar)
            .toolbarColorScheme(scheme, for: .navigationBar)
            .alert("Saved", isPresented: $showingSaved) { Button("OK", role: .cancel) {} }
        }
    }

    private func saveBaseURL() {
        UserDefaults.standard.set(baseURLString, forKey: "API_BASE_URL")
        if let url = URL(string: baseURLString) {
            app.apiBaseURL = url
        }
        showingSaved = true
    }
}
