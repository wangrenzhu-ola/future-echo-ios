import SwiftUI

enum EchoPalette {
    static let ink = Color(red: 16 / 255, green: 24 / 255, blue: 39 / 255)
    static let coral = Color(red: 242 / 255, green: 125 / 255, blue: 106 / 255)
    static let mist = Color(red: 123 / 255, green: 199 / 255, blue: 196 / 255)
    static let sand = Color(red: 189 / 255, green: 181 / 255, blue: 164 / 255)
    static let dusk = Color(red: 128 / 255, green: 137 / 255, blue: 176 / 255)
    static let paper = Color(red: 245 / 255, green: 243 / 255, blue: 236 / 255)
}

extension PromiseTheme {
    var color: Color {
        switch self {
        case .coral: return EchoPalette.coral
        case .mist: return EchoPalette.mist
        case .sand: return EchoPalette.sand
        case .dusk: return EchoPalette.dusk
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

struct EchoBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [EchoPalette.ink, EchoPalette.ink.opacity(0.92)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct EchoRing: View {
    let progress: Double
    let accent: Color
    var isStatic = false

    var body: some View {
        ZStack {
            ForEach(0..<4) { index in
                Circle()
                    .stroke(accent.opacity(0.56 - Double(index) * 0.1), lineWidth: index == 0 ? 3 : 1)
                    .scaleEffect(ringScale(index: index))
            }
            Circle()
                .fill(accent.opacity(0.16))
                .scaleEffect(0.42)
            Image(systemName: "waveform.path")
                .font(.system(size: 30, weight: .light))
                .foregroundColor(accent)
                .accessibilityHidden(true)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func ringScale(index: Int) -> CGFloat {
        let base = 0.42 + CGFloat(index) * 0.16
        guard !isStatic else { return base }
        return base + CGFloat(progress) * 0.08
    }
}

struct SplitHorizon: View {
    let promise: SavingsPromise

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(promise.title)
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                    Text("Your promise")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.62))
                }
                Spacer()
                Text(EchoFormatters.currency(promise.targetAmount))
                    .font(.system(.title3, design: .rounded).monospacedDigit())
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(promise.themeToken.color)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 8)
            HStack {
                Label(EchoFormatters.currency(promise.currentSavedAmount), systemImage: "circle.fill")
                    .foregroundColor(promise.themeToken.color)
                Spacer()
                Text("Goal")
                    .foregroundColor(.white.opacity(0.66))
            }
            .font(.caption.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.075))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(promise.themeToken.color.opacity(0.38), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(promise.title), \(EchoFormatters.currency(promise.currentSavedAmount)) saved toward \(EchoFormatters.currency(promise.targetAmount))"
        )
    }

    private var progress: CGFloat {
        let target = NSDecimalNumber(decimal: promise.targetAmount).doubleValue
        let current = NSDecimalNumber(decimal: promise.currentSavedAmount).doubleValue
        guard target > 0 else { return 0 }
        return CGFloat(min(max(current / target, 0), 1))
    }
}

struct EmptyEchoIllustration: View {
    let accent: Color

    var body: some View {
        ZStack {
            EchoRing(progress: 0, accent: accent, isStatic: true)
            Capsule()
                .fill(accent.opacity(0.8))
                .frame(height: 2)
                .padding(.horizontal, 24)
        }
        .frame(width: 150, height: 150)
        .accessibilityHidden(true)
    }
}

struct PrimaryEchoButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundColor(EchoPalette.ink)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.opacity(configuration.isPressed ? 0.72 : 1))
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct InlineNoticeView: View {
    let message: String
    let isError: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isError ? "exclamationmark.circle" : "checkmark.circle")
            Text(message)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.footnote)
        .foregroundColor(isError ? EchoPalette.coral : EchoPalette.mist)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .accessibilityIdentifier(isError ? "inline.error" : "inline.notice")
    }
}
