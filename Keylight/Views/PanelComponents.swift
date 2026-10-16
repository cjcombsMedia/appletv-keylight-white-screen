import SwiftUI

// MARK: - Chip

/// A compact selectable button. tvOS focus is read from the environment so the whole
/// panel highlights consistently instead of relying on the default card treatment.
struct Chip: View {
    let title: String
    var subtitle: String? = nil
    var swatch: Color? = nil
    var systemImage: String? = nil
    var isSelected: Bool = false
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ChipLabel(title: title,
                      subtitle: subtitle,
                      swatch: swatch,
                      systemImage: systemImage,
                      isSelected: isSelected,
                      isDestructive: isDestructive)
        }
        .buttonStyle(.plain)
    }
}

private struct ChipLabel: View {
    @Environment(\.isFocused) private var isFocused

    let title: String
    let subtitle: String?
    let swatch: Color?
    let systemImage: String?
    let isSelected: Bool
    let isDestructive: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let swatch {
                Circle()
                    .fill(swatch)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
            }
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(foreground.opacity(0.6))
                }
            }
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(background, in: Capsule())
        .overlay(
            Capsule().strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .scaleEffect(isFocused ? 1.06 : 1.0)
        .animation(.easeOut(duration: 0.12), value: isFocused)
    }

    private var foreground: Color {
        if isFocused { return .black }
        if isDestructive { return Color(red: 1, green: 0.55, blue: 0.5) }
        return isSelected ? .white : .white.opacity(0.75)
    }

    private var background: Color {
        if isFocused { return .white }
        return isSelected ? Color.white.opacity(0.20) : Color.white.opacity(0.07)
    }

    private var borderColor: Color {
        if isFocused { return .white }
        return isSelected ? Color.white.opacity(0.55) : Color.white.opacity(0.12)
    }
}

// MARK: - Value row

/// A full-width row whose value is driven by left / right on the remote.
///
/// Because the row spans the panel there is nothing focusable beside it, so tvOS hands
/// the horizontal move commands to us instead of moving focus — the standard way to
/// build a usable slider on this platform.
struct ValueRow: View {
    let title: String
    let value: String
    let fraction: Double
    var accentLeft: String? = nil
    var accentRight: String? = nil
    let onAdjust: (Double) -> Void

    @State private var accelerator = MoveAccelerator()

    /// Focus is tracked explicitly rather than read from `\.isFocused`: that environment
    /// value reports the nearest focusable *ancestor*, and here the row is the focusable
    /// itself, so it would always read false.
    @FocusState private var isFocused: Bool

    var body: some View {
        ValueRowLabel(title: title,
                      value: value,
                      fraction: fraction,
                      accentLeft: accentLeft,
                      accentRight: accentRight,
                      isFocused: isFocused)
            .focusable(true)
            .focused($isFocused)
            .onMoveCommand { direction in
                switch direction {
                case .left:  onAdjust(-accelerator.multiplier(for: direction))
                case .right: onAdjust(accelerator.multiplier(for: direction))
                default:     break
                }
            }
    }
}

private struct ValueRowLabel: View {
    let title: String
    let value: String
    let fraction: Double
    let accentLeft: String?
    let accentRight: String?
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                Spacer()
                if isFocused {
                    Image(systemName: "chevron.compact.left")
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Image(systemName: "chevron.compact.right")
                } else {
                    Text(value)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(isFocused ? .black : .white.opacity(0.85))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(isFocused ? Color.black.opacity(0.18) : Color.white.opacity(0.12))
                    .frame(height: 10)
                GeometryReader { geo in
                    Capsule()
                        .fill(isFocused ? Color.black.opacity(0.75) : Color.white.opacity(0.6))
                        .frame(width: max(10, geo.size.width * min(max(fraction, 0), 1)), height: 10)
                }
                .frame(height: 10)
            }

            if let accentLeft, let accentRight {
                HStack {
                    Text(accentLeft)
                    Spacer()
                    Text(accentRight)
                }
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(isFocused ? .black.opacity(0.5) : .white.opacity(0.35))
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 16)
        .background(isFocused ? Color.white : Color.white.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.easeOut(duration: 0.12), value: isFocused)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.45))
            if let detail {
                Text(detail)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            }
            Spacer()
        }
        .padding(.top, 6)
    }
}
