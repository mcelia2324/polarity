import SwiftUI

enum Theme {
    // Adaptive colors that work in both light and dark mode
    static let background = Color("background", bundle: nil)
    static let backgroundTop = Color("backgroundTop", bundle: nil)
    static let card = Color("card", bundle: nil)
    static let accent = Color(red: 0.71, green: 0.36, blue: 0.18)
    static let accentDark = Color("accentDark", bundle: nil)
    static let ink = Color("ink", bundle: nil)
    static let muted = Color("muted", bundle: nil)
    static let cardShadow = Color("cardShadow", bundle: nil)

    // Fallbacks for when color assets aren't available
    static let backgroundLight = Color(red: 0.96, green: 0.94, blue: 0.91)
    static let backgroundDark = Color(red: 0.11, green: 0.11, blue: 0.12)

    static let appBackground = LinearGradient(
        colors: [backgroundTop, background],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Theme.cardShadow, radius: 18, x: 0, y: 8)
    }
}

struct ReadableWidthModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    func readableWidth() -> some View {
        modifier(ReadableWidthModifier())
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
