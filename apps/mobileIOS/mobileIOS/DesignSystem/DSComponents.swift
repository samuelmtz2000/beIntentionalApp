//
//  DSComponents.swift
//  mobileIOS
//
//  Extended Design System components for consistent UI across features
//

import SwiftUI

// MARK: - Navigation Components

struct DSNavigationPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 20, height: 20)
                
                if isSelected {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, isSelected ? 16 : 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .animation(.easeInOut(duration: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Header Components

struct DSSectionHeader: View {
    let title: String
    let icon: String?
    let iconColor: Color?
    let trailingIcon: String?
    let onTrailingTap: (() -> Void)?
    let trailingColor: Color?
    
    @Environment(\.colorScheme) private var scheme
    
    init(
        title: String,
        icon: String? = nil,
        iconColor: Color? = nil,
        trailingIcon: String? = nil,
        onTrailingTap: (() -> Void)? = nil,
        trailingColor: Color? = nil
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.trailingIcon = trailingIcon
        self.onTrailingTap = onTrailingTap
        self.trailingColor = trailingColor
    }
    
    var body: some View {
        let c = DSTheme.colors(for: scheme)
        
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(iconColor ?? c.textPrimary)
                    .font(.system(size: 18, weight: .semibold))
            }
            Text(title)
                .dsFont(.headerMD)
                .foregroundStyle(c.textPrimary)
            Spacer()
            if let trailingIcon = trailingIcon, let onTap = onTrailingTap {
                Button(action: onTap) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(trailingColor ?? c.accentSecondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            // Overlay background so header reads well when pinned while scrolling
            c.backgroundSecondary
                .overlay(
                    Rectangle()
                        .fill(c.divider)
                        .frame(height: 0.5)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                )
        )
    }
}

// MARK: - Card Components

struct DSCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let content: () -> Content
    
    var body: some View {
        content()
            .cardStyle()
    }
}

// MARK: - Banner Components

struct DSInfoBanner: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        let c = DSTheme.colors(for: scheme)
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(c.accentPrimary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .dsFont(.headerMD)
                    .foregroundStyle(c.textPrimary)
                Text(message)
                    .dsFont(.caption)
                    .foregroundStyle(c.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            DSButton(actionTitle, style: .secondary, action: action)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(c.surfaceCard))
    }
}

struct DSCardRow: View {
    let title: String
    let subtitle: String?
    let leadingIcon: String?
    let trailingContent: AnyView?
    
    init(
        title: String,
        subtitle: String? = nil,
        leadingIcon: String? = nil,
        trailingContent: AnyView? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.trailingContent = trailingContent
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = leadingIcon {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .dsFont(.body)
                    .foregroundStyle(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .dsFont(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let trailing = trailingContent {
                trailing
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Form Components

struct DSFormField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    
    init(
        label: String,
        text: Binding<String>,
        placeholder: String = "",
        keyboardType: UIKeyboardType = .default
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .dsFont(.caption)
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboardType)
        }
    }
}

struct DSToggleField: View {
    let label: String
    @Binding var isOn: Bool
    let helpText: String?
    
    init(label: String, isOn: Binding<Bool>, helpText: String? = nil) {
        self.label = label
        self._isOn = isOn
        self.helpText = helpText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(label, isOn: $isOn)
                .dsFont(.body)
            
            if let help = helpText {
                Text(help)
                    .dsFont(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
            }
        }
    }
}

struct DSPickerField<T: Hashable>: View {
    let label: String
    @Binding var selection: T
    let options: [T]
    let displayName: (T) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .dsFont(.caption)
                .foregroundStyle(.secondary)
            
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayName(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }
}

// MARK: - Button Components

struct DSButton: View {
    enum Style {
        case primary
        case secondary
        case destructive
    }
    
    let title: String
    let icon: String?
    let style: Style
    let action: () -> Void
    
    @Environment(\.isEnabled) private var isEnabled
    
    init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    @ViewBuilder
    var body: some View {
        switch style {
        case .primary:
            Button(action: action) {
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        case .secondary:
            Button(action: action) {
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        case .destructive:
            Button(action: action) {
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .buttonStyle(DestructiveButtonStyle())
        }
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        let c = DSTheme.colors(for: scheme)
        let state = DSTheme.StateOpacity()
        
        return configuration.label
            .foregroundStyle(isEnabled ? .white : Color.white.opacity(state.disabled))
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 24).fill(isEnabled ? c.error : c.error.opacity(1 - state.disabled)))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(configuration.isPressed ? state.pressed : 0))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// MARK: - Progress Components

struct DSProgressBar: View {
    let value: Double
    let total: Double
    let label: String?
    let showPercentage: Bool
    let tintColor: Color?
    
    @Environment(\.colorScheme) private var scheme
    
    init(
        value: Double,
        total: Double,
        label: String? = nil,
        showPercentage: Bool = false,
        tintColor: Color? = nil
    ) {
        self.value = value
        self.total = total
        self.label = label
        self.showPercentage = showPercentage
        self.tintColor = tintColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = label {
                HStack {
                    Text(label)
                        .dsFont(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if showPercentage {
                        Text("\(Int((value / max(total, 1)) * 100))%")
                            .dsFont(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            ProgressView(value: value, total: max(total, 1))
                .tint(tintColor ?? DSTheme.colors(for: scheme).accentPrimary)
        }
    }
}

// MARK: - Empty State

struct DSEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text(title)
                .dsFont(.headerMD)
            
            Text(message)
                .dsFont(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                DSButton(actionTitle, style: .primary, action: action)
                    .padding(.top, 8)
            }
        }
        .padding(32)
    }
}
