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

extension View {
    func cardStyle() -> some View { modifier(CardModifier()) }
}

