import SwiftUI

enum Theme {
    static let background = Color(red: 0.96, green: 0.94, blue: 0.91)
    static let backgroundTop = Color(red: 0.92, green: 0.88, blue: 0.82)
    static let card = Color(red: 1.0, green: 0.98, blue: 0.95)
    static let accent = Color(red: 0.71, green: 0.36, blue: 0.18)
    static let accentDark = Color(red: 0.48, green: 0.22, blue: 0.09)
    static let ink = Color(red: 0.12, green: 0.10, blue: 0.09)
    static let muted = Color(red: 0.42, green: 0.37, blue: 0.32)

    static let appBackground = LinearGradient(
        colors: [backgroundTop, background],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.card)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
