import SwiftUI

enum BrandTheme: String, CaseIterable, Identifiable, Codable {
    case purple
    case neonGreen
    case pink
    case blue
    case black

    var id: String { rawValue }

    var title: String {
        switch self {
        case .purple: return "Purple"
        case .neonGreen: return "Green"
        case .pink: return "Pink"
        case .blue: return "Blue"
        case .black: return "Black"
        }
    }

    var accent: Color {
        switch self {
        case .purple: return Color(red: 0.62, green: 0.43, blue: 1.00)
        case .neonGreen: return Color(red: 0.70, green: 1.00, blue: 0.22)
        case .pink: return Color(red: 1.00, green: 0.38, blue: 0.72)
        case .blue: return Color(red: 0.26, green: 0.68, blue: 1.00)
        case .black: return Color(red: 0.86, green: 0.88, blue: 0.84)
        }
    }

    var backgroundTop: Color {
        switch self {
        case .purple: return Color(red: 0.05, green: 0.03, blue: 0.10)
        case .neonGreen: return Color.black
        case .pink: return Color(red: 0.10, green: 0.03, blue: 0.07)
        case .blue: return Color(red: 0.02, green: 0.05, blue: 0.10)
        case .black: return Color.black
        }
    }

    var backgroundBottom: Color {
        switch self {
        case .purple: return Color(red: 0.025, green: 0.022, blue: 0.040)
        case .neonGreen: return Color(red: 0.018, green: 0.021, blue: 0.019)
        case .pink: return Color(red: 0.035, green: 0.020, blue: 0.030)
        case .blue: return Color(red: 0.016, green: 0.025, blue: 0.040)
        case .black: return Color(red: 0.025, green: 0.026, blue: 0.025)
        }
    }
}

enum BrandThemeStore {
    static let storageKey = "fytrr.backgroundTheme"

    static var current: BrandTheme {
        get {
            let rawValue = UserDefaults.standard.string(forKey: storageKey) ?? BrandTheme.neonGreen.rawValue
            return BrandTheme(rawValue: rawValue) ?? .neonGreen
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }
}

enum BrandPalette {
    static var theme: BrandTheme { BrandThemeStore.current }
    static var backgroundTop: Color { theme.backgroundTop }
    static var backgroundBottom: Color { theme.backgroundBottom }
    static let surface = Color(red: 0.055, green: 0.058, blue: 0.056)
    static let elevated = Color(red: 0.085, green: 0.09, blue: 0.086)
    static let overlay = Color.white.opacity(0.07)
    static var stroke: Color { accent.opacity(0.18) }
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.75, green: 0.78, blue: 0.74)
    static let textTertiary = Color(red: 0.50, green: 0.54, blue: 0.49)
    static var accent: Color { theme.accent }
    static let accentSecondary = Color.white
    static var success: Color { theme.accent }
    static let warning = Color(red: 1.00, green: 0.74, blue: 0.28)
    static let destructive = Color(red: 1.00, green: 0.24, blue: 0.24)
}

struct BrandBackground: View {
    var body: some View {
        LinearGradient(
            colors: [BrandPalette.backgroundTop, BrandPalette.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [BrandPalette.accent.opacity(0.08), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)
        }
        .ignoresSafeArea()
    }
}

struct BrandCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(BrandPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(BrandPalette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct BrandPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("AvenirNextCondensed-Heavy", size: 16))
            .tracking(0)
            .foregroundStyle(.black)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(BrandPalette.accent.opacity(configuration.isPressed ? 0.78 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: BrandPalette.accent.opacity(configuration.isPressed ? 0.12 : 0.25), radius: 14, x: 0, y: 6)
    }
}

struct BrandSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("AvenirNextCondensed-DemiBold", size: 15))
            .tracking(0)
            .foregroundStyle(BrandPalette.textPrimary)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(BrandPalette.elevated.opacity(configuration.isPressed ? 0.72 : 1.0))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(BrandPalette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct BrandMark: View {
    var height: CGFloat = 48

    var body: some View {
        BrandMarkFallback()
            .fill(BrandPalette.accent)
            .frame(width: height * 0.78, height: height)
            .accessibilityLabel("FYTRR mark")
    }
}

struct BrandNeonLogo: View {
    var size: CGFloat = 168

    var body: some View {
        Image("FYTRRLogo")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("FYTRR logo")
    }
}

struct BrandWordmark: View {
    var height: CGFloat = 28

    var body: some View {
        Image("FYTRRWordmark")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel("FYTRR wordmark")
    }
}

struct BrandMarkFallback: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let top = CGRect(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.02, width: rect.width * 0.88, height: rect.height * 0.29)
        let middle = CGRect(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.34, width: rect.width * 0.70, height: rect.height * 0.28)
        let bottom = CGRect(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.66, width: rect.width * 0.40, height: rect.height * 0.28)

        path.addRoundedRect(in: top, cornerSize: CGSize(width: rect.width * 0.09, height: rect.width * 0.09))
        path.addRoundedRect(in: middle, cornerSize: CGSize(width: rect.width * 0.09, height: rect.width * 0.09))
        path.addRoundedRect(in: bottom, cornerSize: CGSize(width: rect.width * 0.09, height: rect.width * 0.09))

        let shear = CGAffineTransform(a: 1, b: 0, c: -0.55, d: 1, tx: rect.width * 0.36, ty: 0)
        return path.applying(shear)
    }
}

struct BrandLogoLockup: View {
    var markHeight: CGFloat = 56
    var wordmarkHeight: CGFloat = 30
    var spacing: CGFloat = 10
    var alignment: HorizontalAlignment = .leading
    var showsMark: Bool = true

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            if showsMark {
                BrandMark(height: markHeight)
            }
            BrandWordmark(height: wordmarkHeight)
        }
    }
}

struct BrandInlineLockup: View {
    var markHeight: CGFloat = 22
    var wordmarkHeight: CGFloat = 24
    var spacing: CGFloat = 10

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            BrandMark(height: markHeight)
            BrandWordmark(height: wordmarkHeight)
        }
    }
}

extension View {
    func brandCard() -> some View {
        modifier(BrandCardModifier())
    }

    func brandFieldStyle() -> some View {
        self
            .font(.custom("AvenirNext-Medium", size: 16))
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(BrandPalette.elevated)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(BrandPalette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(BrandPalette.textPrimary)
            .tint(BrandPalette.accent)
    }
}
