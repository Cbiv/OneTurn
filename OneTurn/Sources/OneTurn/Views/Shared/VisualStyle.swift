import SwiftUI

struct ThemeDefinition: Equatable {
    var background: [Color]
    var atmosphereA: Color
    var atmosphereB: Color
    var cardTop: Color
    var cardBottom: Color
    var boardTop: Color
    var boardBottom: Color
    var textPrimary: Color
    var textSecondary: Color
    var accent: Color
    var accentSoft: Color
    var glow: Color
    var success: Color
    var failure: Color
    var tileLine: Color
    var tileShadow: Color
    var panelStroke: Color
    var panelShadow: Color
    var grain: Color

    var cardFill: LinearGradient {
        LinearGradient(colors: [cardTop, cardBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var boardFill: LinearGradient {
        LinearGradient(colors: [boardTop, boardBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func definition(for choice: ThemeChoice) -> ThemeDefinition {
        switch choice {
        case .nocturne:
            ThemeDefinition(
                background: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.08, green: 0.09, blue: 0.13),
                    Color(red: 0.11, green: 0.13, blue: 0.18)
                ],
                atmosphereA: Color(red: 0.71, green: 0.53, blue: 0.3),
                atmosphereB: Color(red: 0.37, green: 0.63, blue: 0.73),
                cardTop: Color.white.opacity(0.12),
                cardBottom: Color.white.opacity(0.05),
                boardTop: Color(red: 0.13, green: 0.14, blue: 0.18),
                boardBottom: Color(red: 0.08, green: 0.09, blue: 0.12),
                textPrimary: Color(red: 0.95, green: 0.93, blue: 0.9),
                textSecondary: Color(red: 0.69, green: 0.72, blue: 0.76),
                accent: Color(red: 0.87, green: 0.77, blue: 0.47),
                accentSoft: Color(red: 0.58, green: 0.82, blue: 0.84),
                glow: Color(red: 0.82, green: 0.55, blue: 0.68),
                success: Color(red: 0.73, green: 0.89, blue: 0.72),
                failure: Color(red: 0.77, green: 0.56, blue: 0.61),
                tileLine: Color.white.opacity(0.11),
                tileShadow: Color.black.opacity(0.35),
                panelStroke: Color.white.opacity(0.17),
                panelShadow: Color.black.opacity(0.35),
                grain: Color.white.opacity(0.05)
            )
        case .paperBloom:
            ThemeDefinition(
                background: [
                    Color(red: 0.97, green: 0.95, blue: 0.91),
                    Color(red: 0.9, green: 0.86, blue: 0.82),
                    Color(red: 0.93, green: 0.9, blue: 0.86)
                ],
                atmosphereA: Color(red: 0.8, green: 0.52, blue: 0.47),
                atmosphereB: Color(red: 0.58, green: 0.68, blue: 0.54),
                cardTop: Color.white.opacity(0.78),
                cardBottom: Color(red: 0.93, green: 0.89, blue: 0.83).opacity(0.82),
                boardTop: Color(red: 0.98, green: 0.96, blue: 0.93),
                boardBottom: Color(red: 0.92, green: 0.88, blue: 0.82),
                textPrimary: Color(red: 0.12, green: 0.11, blue: 0.1),
                textSecondary: Color(red: 0.37, green: 0.35, blue: 0.32),
                accent: Color(red: 0.77, green: 0.44, blue: 0.39),
                accentSoft: Color(red: 0.47, green: 0.61, blue: 0.47),
                glow: Color(red: 0.88, green: 0.72, blue: 0.58),
                success: Color(red: 0.35, green: 0.54, blue: 0.39),
                failure: Color(red: 0.56, green: 0.42, blue: 0.42),
                tileLine: Color.black.opacity(0.08),
                tileShadow: Color(red: 0.45, green: 0.37, blue: 0.3).opacity(0.18),
                panelStroke: Color.white.opacity(0.5),
                panelShadow: Color(red: 0.42, green: 0.33, blue: 0.28).opacity(0.16),
                grain: Color.black.opacity(0.035)
            )
        case .electricQuiet:
            ThemeDefinition(
                background: [
                    Color(red: 0.1, green: 0.08, blue: 0.15),
                    Color(red: 0.09, green: 0.12, blue: 0.21),
                    Color(red: 0.15, green: 0.14, blue: 0.27)
                ],
                atmosphereA: Color(red: 0.96, green: 0.75, blue: 0.7),
                atmosphereB: Color(red: 0.65, green: 0.93, blue: 0.83),
                cardTop: Color.white.opacity(0.11),
                cardBottom: Color.white.opacity(0.05),
                boardTop: Color(red: 0.15, green: 0.14, blue: 0.24),
                boardBottom: Color(red: 0.1, green: 0.1, blue: 0.17),
                textPrimary: Color(red: 0.95, green: 0.93, blue: 0.98),
                textSecondary: Color(red: 0.73, green: 0.69, blue: 0.82),
                accent: Color(red: 0.97, green: 0.79, blue: 0.69),
                accentSoft: Color(red: 0.63, green: 0.94, blue: 0.84),
                glow: Color(red: 0.84, green: 0.73, blue: 0.98),
                success: Color(red: 0.7, green: 0.9, blue: 0.8),
                failure: Color(red: 0.81, green: 0.58, blue: 0.69),
                tileLine: Color.white.opacity(0.12),
                tileShadow: Color.black.opacity(0.33),
                panelStroke: Color.white.opacity(0.18),
                panelShadow: Color.black.opacity(0.34),
                grain: Color.white.opacity(0.045)
            )
        }
    }
}

struct GlassCard<Content: View>: View {
    let theme: ThemeDefinition
    let content: Content

    init(theme: ThemeDefinition, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.content = content()
    }

    var body: some View {
        content
            .padding(22)
            .background {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(theme.cardFill)
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.14), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .blur(radius: 2)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(theme.panelStroke, lineWidth: 1)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(theme.tileLine, lineWidth: 1)
                            .padding(1.5)
                    }
                    .shadow(color: theme.panelShadow, radius: 28, y: 18)
            }
    }
}

struct OrbButtonStyle: ButtonStyle {
    let theme: ThemeDefinition

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(theme.textPrimary)
            .frame(width: 50, height: 50)
            .background {
                Circle()
                    .fill(theme.cardFill)
                    .overlay {
                        Circle()
                            .stroke(theme.panelStroke, lineWidth: 1)
                    }
                    .shadow(color: theme.panelShadow.opacity(configuration.isPressed ? 0.18 : 0.3), radius: 14, y: 8)
            }
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

struct PillActionButtonStyle: ButtonStyle {
    let theme: ThemeDefinition
    var accent: Color? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.88)
            .foregroundStyle(theme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 46)
            .background(
                Capsule(style: .continuous)
                    .fill((accent ?? Color.clear).opacity(accent == nil ? 0 : 0.18))
                    .background(theme.cardFill, in: Capsule(style: .continuous))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(theme.panelStroke, lineWidth: 1)
                    )
            )
            .opacity(configuration.isPressed ? 0.84 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.84), value: configuration.isPressed)
    }
}

struct GradientBackdrop: View {
    let theme: ThemeChoice
    var animated = true
    @State private var shift = false

    var body: some View {
        let definition = ThemeDefinition.definition(for: theme)

        ZStack {
            LinearGradient(
                colors: definition.background,
                startPoint: shift ? .topLeading : .bottomTrailing,
                endPoint: shift ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [definition.atmosphereA.opacity(0.18), .clear],
                center: shift ? .topLeading : .trailing,
                startRadius: 30,
                endRadius: 360
            )
            .ignoresSafeArea()
            .blur(radius: 18)

            RadialGradient(
                colors: [definition.atmosphereB.opacity(0.16), .clear],
                center: shift ? .bottomTrailing : .leading,
                startRadius: 40,
                endRadius: 320
            )
            .ignoresSafeArea()
            .blur(radius: 22)

            GalleryLightBlob(color: definition.glow.opacity(0.12), size: 320, offset: shift ? CGSize(width: -110, height: -260) : CGSize(width: 120, height: -110))
            GalleryLightBlob(color: definition.accentSoft.opacity(0.12), size: 260, offset: shift ? CGSize(width: 150, height: 250) : CGSize(width: -110, height: 130))
            GalleryLightBlob(color: definition.atmosphereA.opacity(0.08), size: 220, offset: shift ? CGSize(width: -150, height: 180) : CGSize(width: 80, height: 210))

            NoiseOverlay(color: definition.grain)
                .ignoresSafeArea()
                .blendMode(.softLight)
                .opacity(0.9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(animated ? .easeInOut(duration: 22).repeatForever(autoreverses: true) : nil, value: shift)
        .onAppear { shift = animated }
        .onChange(of: animated) { _, isAnimated in
            shift = isAnimated
        }
    }
}

private struct GalleryLightBlob: View {
    let color: Color
    let size: CGFloat
    let offset: CGSize

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 40)
            .offset(offset)
    }
}

private struct NoiseOverlay: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let width = proxy.size.width
                let height = proxy.size.height
                let columns = max(Int(width / 12), 1)
                let rows = max(Int(height / 12), 1)

                for row in 0..<rows {
                    for column in 0..<columns where (row * 17 + column * 11) % 5 == 0 {
                        let x = (CGFloat(column) / CGFloat(columns)) * width
                        let y = (CGFloat(row) / CGFloat(rows)) * height
                        let size = CGFloat(((row + column) % 3) + 1)
                        path.addEllipse(in: CGRect(x: x, y: y, width: size, height: size))
                    }
                }
            }
            .fill(color.opacity(0.55))
        }
    }
}
