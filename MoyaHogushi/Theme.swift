import SwiftUI
import UIKit

enum Theme {
    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    static let background    = adaptive(0xE7ECEF, 0x141A1F)   // 霧の青灰
    static let card          = adaptive(0xFFFFFF, 0x1C242A)
    static let cardSoft      = adaptive(0xF3F6F7, 0x222B31)
    static let line          = adaptive(0xD4DCDF, 0x2C363C)
    static let text          = adaptive(0x20282D, 0xE9EEF0)
    static let secondaryText = adaptive(0x5D6A71, 0xAAB6BB)
    static let tertiaryText  = adaptive(0x8A969C, 0x718089)
    static let mist          = adaptive(0xC3D1D8, 0x38444C)
    static let accent        = adaptive(0xD9743C, 0xEF8C53)   // 霧が晴れて差す光
    static let accentSoft    = adaptive(0xF3DCC9, 0x3C2D21)
    static let accentInk     = adaptive(0x8C461C, 0xF7C9A3)
    static let onAccent      = adaptive(0xFFFFFF, 0x1A1208)
    static let good          = adaptive(0x6B8F71, 0x89B08F)
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.line, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardModifier()) }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.bold))
            .foregroundColor(isEnabled ? Theme.onAccent : Theme.tertiaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? Theme.accent : Theme.line)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.medium))
            .foregroundColor(Theme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
