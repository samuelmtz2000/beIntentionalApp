import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable { case system, light, dark; var id: String { rawValue } }

struct DSTheme {
    struct Colors {
        let backgroundPrimary: Color
        let backgroundSecondary: Color
        let surfaceCard: Color
        let accentPrimary: Color
        let accentSecondary: Color
        let highlight: Color
        let textPrimary: Color
        let textSecondary: Color
        let divider: Color
        let success: Color
        let warning: Color
        let error: Color
    }

    struct Spacing { let xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 16, lg: CGFloat = 24, xl: CGFloat = 32 }
    struct Radii { let small: CGFloat = 8, medium: CGFloat = 16, large: CGFloat = 24, full: CGFloat = 9999 }
    struct StateOpacity { let hover: Double = 0.08, pressed: Double = 0.14, disabled: Double = 0.38 }
    struct Motion { let fast: Double = 0.2, standard: Double = 0.3 }

    enum TypeScale {
        case headerLG, headerMD, body, caption
        var font: Font {
            switch self {
            case .headerLG: return .title3
            case .headerMD: return .headline
            case .body: return .body
            case .caption: return .caption
            }
        }
    }

    static func colors(for scheme: ColorScheme) -> Colors {
        if scheme == .dark {
            return Colors(
                backgroundPrimary: Color(hex: "#0D0D0F"),
                backgroundSecondary: Color(hex: "#1A1B20"),
                surfaceCard: Color(hex: "#23242A"),
                accentPrimary: Color(hex: "#6A5ACD"),
                accentSecondary: Color(hex: "#00C2FF"),
                highlight: Color(hex: "#9B51E0"),
                textPrimary: Color(hex: "#FFFFFF"),
                textSecondary: Color(hex: "#A0A4AF"),
                divider: Color(hex: "#2E2F36"),
                success: Color(hex: "#00E676"),
                warning: Color(hex: "#FFC107"),
                error: Color(hex: "#FF5252")
            )
        } else {
            return Colors(
                backgroundPrimary: Color(hex: "#F9FAFB"),
                backgroundSecondary: Color(hex: "#FFFFFF"),
                surfaceCard: Color(hex: "#F2F3F7"),
                accentPrimary: Color(hex: "#6A5ACD"),
                accentSecondary: Color(hex: "#00A8E8"),
                highlight: Color(hex: "#BB6BD9"),
                textPrimary: Color(hex: "#1A1B1E"),
                textSecondary: Color(hex: "#6B7280"),
                divider: Color(hex: "#E5E7EB"),
                success: Color(hex: "#16A34A"),
                warning: Color(hex: "#F59E0B"),
                error: Color(hex: "#DC2626")
            )
        }
    }
}

struct PillButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        let c = DSTheme.colors(for: scheme)
        return configuration.label
            .foregroundStyle(isSelected ? Color.white : c.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? c.accentPrimary : c.surfaceCard)
            )
            .shadow(color: isSelected ? c.accentPrimary.opacity(configuration.isPressed ? 0.2 : 0.35) : .clear, radius: isSelected ? 8 : 0, x: 0, y: 0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: DSTheme.Motion().fast), value: configuration.isPressed)
    }
}

struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        let c = DSTheme.colors(for: scheme)
        content
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24).fill(c.surfaceCard))
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.6 : 0.08), radius: 10, x: 0, y: 4)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        let c = DSTheme.colors(for: scheme)
        let state = DSTheme.StateOpacity()
        return configuration.label
            .foregroundStyle(isEnabled ? c.textPrimary : c.textPrimary.opacity(state.disabled))
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 24).fill(isEnabled ? c.accentPrimary : c.accentPrimary.opacity(1 - state.disabled)))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(configuration.isPressed ? state.pressed : 0))
            )
            .shadow(color: c.accentPrimary.opacity(0.25), radius: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        let c = DSTheme.colors(for: scheme)
        let state = DSTheme.StateOpacity()
        return configuration.label
            .foregroundStyle(isEnabled ? c.accentPrimary : c.accentPrimary.opacity(state.disabled))
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 16).fill(c.surfaceCard))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isEnabled ? c.accentPrimary : c.accentPrimary.opacity(state.disabled), lineWidth: 1))
            .overlay(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(configuration.isPressed ? state.pressed : 0)))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// MARK: - Toast Components

struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval
    
    init(message: String, type: ToastType, duration: TimeInterval = 3.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

enum ToastType {
    case success, error, info
    
    func icon() -> String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    func color(_ colors: DSTheme.Colors) -> Color {
        switch self {
        case .success: return colors.success
        case .error: return colors.error
        case .info: return colors.accentSecondary
        }
    }
}

struct ToastView: View {
    let toast: ToastMessage
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        let colors = DSTheme.colors(for: scheme)
        
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon())
                .foregroundStyle(toast.type.color(colors))
                .font(.system(size: 16, weight: .medium))
            
            Text(toast.message)
                .dsFont(.body)
                .foregroundStyle(colors.textPrimary)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surfaceCard)
                .shadow(color: Color.black.opacity(scheme == .dark ? 0.4 : 0.15), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let toast = toast {
                VStack {
                    ToastView(toast: toast)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    Spacer()
                }
                .zIndex(1000)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: toast.id)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            self.toast = nil
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardModifier()) }
    func dsFont(_ scale: DSTheme.TypeScale) -> some View { self.font(scale.font) }
    func toast(_ toast: Binding<ToastMessage?>) -> some View { modifier(ToastModifier(toast: toast)) }
}
