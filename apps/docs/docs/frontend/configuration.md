---
title: Configuration
---

Base URL
- Stored in `UserDefaults` under `apiBaseURL`
- Default: `http://localhost:4000`

Example Settings View
```swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("apiBaseURL") private var apiBaseURL = "http://localhost:4000"

    var body: some View {
        Form {
            Section("Network") {
                TextField("API Base URL", text: $apiBaseURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Text("Ex: http://localhost:4000").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
```

Other Settings (future)
- Analytics opt‑in, theme, haptics

