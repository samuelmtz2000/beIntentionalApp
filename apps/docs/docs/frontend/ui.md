---
title: UI & Components
---

SwiftUI views are small, composable, and previewable. Emphasize accessibility and performance.

<<<<<<< HEAD
## UI Navigation Patterns

- **Tab Navigation**: Streamlined 2-tab interface (Habits, Settings) for primary app sections. The Today tab has been removed for simplified navigation.
- **Pill Navigation**: Within screens, use horizontal "chips" to switch between sub-sections (Player / Habits / Areas / Store / Archive). The selected pill is filled (blue), others are neutral. A Config pill opens the User Config sheet.
- **Swipe Actions**: Use swipe actions on list rows. Leading full swipe auto-executes the primary action (Record habit). Trailing swipe reveals Edit/Delete with confirmation prompts.
- **Toast Notifications**: Provide immediate feedback for user actions with top-sliding toast messages that auto-dismiss after 3 seconds.
- **Forms**: Use native SwiftUI Forms. Areas are selected via Picker from the Areas catalog. Bad Habits can be "None (Global)". Avoid manual ID entry.

## Toast Notification System

Toast messages provide immediate visual feedback for habit completions:

```swift
// Usage example
@State private var toast: ToastMessage? = nil

// Show success toast
toast = ToastMessage(message: "✅ Exercise completed! +10 XP, +5 coins", type: .success)

// Show error toast
toast = ToastMessage(message: "⚠️ Smoking recorded. -10 life", type: .error)

// Apply to view
YourView()
  .toast($toast)
```

Toast types:
- **Success** (green with checkmark): Good habit completions showing XP/coin rewards
- **Error** (red with exclamation): Bad habit records showing life penalties
- **Info** (blue with info icon): General informational messages
## Running Challenge UX

- Game Over (health ≤ 0)
  - Header shows a skull icon instead of the heart; banner is hidden in this state.
  - Game Over modal explains the running challenge with the per‑user target distance in km.
  - Bad habits are disabled while in game over.

- Recovery (running challenge)
  - Banner appears with a Details button; Details opens the Running Challenge sheet if Health access is configured, otherwise shows the Game Over modal to start.
  - Running Challenge sheet shows dynamic target (km), a progress bar, and a Started date.
  - “Enable Health Access” is shown until configured; then only “Update Progress” appears.
  - UI‑first completion: when target is reached, show a confetti modal immediately; after dismissing, the app finalizes with the backend, restores health=1000, and returns to active.

## UI Navigation Patterns
- Tab navigation: Primary app sections are exposed via the bottom tab bar (Today, Habits, Settings, etc.). Screens should not hide the tab bar unless in a modal flow.
- Section navigation: Within Habits, use the reusable `MainNavigationBar` (animated pills) to switch Player / Habits / Areas / Store / Archive; a Config pill opens the config sheet.
- Spotify‑like actions: Use swipe actions on list rows. Leading full swipe auto‑executes the primary action (Record). Trailing full swipe opens Edit; Delete is trailing and always asks for confirmation.
- Forms: Use `DSSheet` for all create/edit flows with Cancel/Save in the navigation bar for consistency.

Habits Header (Global XP)
```swift
VStack(alignment: .leading) {
  Text("Lvl \(profile.level)")
    .bold()
    .padding(6)
    .background(Capsule().fill(Color.blue.opacity(0.15)))
  let need = xpNeeded(level: profile.level,
                      base: profile.xpPerLevel,
                      curve: profile.config?.levelCurve ?? "linear",
                      multiplier: profile.config?.levelMultiplier ?? 1.5)
  ProgressView(value: Double(profile.xp), total: Double(max(need,1))) {
    HStack(spacing: 6) {
      Text("XP to next")
      Image(systemName: "arrow.right")
      Text("\(profile.xp) from \(need)")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }
}
```

Config Entry (pill in chip bar)
```swift
MainNavigationBar(selected: $selected, onConfig: { showingConfig = true })
  .sheet(isPresented: $showingConfig) { UserConfigSheet(onSaved: { Task { await profileVM.refresh() } }) }
```

Per‑Area Legend
```swift
ForEach(profile.areas, id: \.areaId) { a in
  // compute need for this level using area curve + multiplier
  let meta = areas.first(where: { $0.id == a.areaId })
  let curve = meta?.levelCurve ?? "linear"
  let mult = meta?.levelMultiplier ?? 1.5
  let need = xpForLevel(level: a.level, base: a.xpPerLevel, curve: curve, multiplier: mult)
  ProgressView(value: Double(a.xp), total: Double(max(need,1))) {
    HStack(spacing: 6) {
      Text("XP to next")
      Image(systemName: "arrow.right")
      Text("\\(a.xp) from \\(need)")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }
}
```

Example Cards + Actions
```swift
import SwiftUI

struct HabitsList: View {
    @ObservedObject var goodVM: HabitsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(goodVM.habits) { habit in
                    DSCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(habit.name).dsFont(.body)
                                HStack(spacing: 8) {
                                    Label("+\(habit.xpReward) XP", systemImage: "star.fill").font(.caption)
                                    Label("+\(habit.coinReward)", systemImage: "creditcard").font(.caption)
                                }
                            }
                            Spacer()
                            DSButton("I did it", icon: "checkmark") {
                                Task { _ = await goodVM.complete(id: habit.id) }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .overlay { if goodVM.isLoading { ProgressView() } }
        .navigationTitle("Habits")
    }
}
```

DSSheet (Cancel/Save)
```swift
DSSheet(title: "New Good Habit", onCancel: { dismiss() }, onSave: { await save() }, canSave: isValid) {
  DSFormField(label: "Name", text: $name)
  DSPickerField(label: "Area", selection: $areaId, options: areas.map(\.id)) { id in
    areas.first { $0.id == id }?.name ?? "Unknown"
  }
  DSFormField(label: "XP", text: $xp, keyboardType: .numberPad)
}
```

Guidelines
- Keep business logic out of views; delegate to view models
- Prefer `Task` for async actions; don’t block the main thread
- Add accessibility labels, traits, and dynamic type support
- Use instruments to spot excessive re‑renders
