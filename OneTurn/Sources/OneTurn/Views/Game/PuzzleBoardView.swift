import SwiftUI

struct PuzzleBoardView: View {
    let puzzle: Puzzle
    let placedMirrors: [Position: TileKind]
    let activated: Set<Position>
    let broken: Set<Position>
    let traversed: Set<Position>
    let mirroredFlash: Position?
    let tokenPosition: Position
    let tokenAnimationDuration: Double
    let theme: ThemeDefinition
    let highContrast: Bool
    let onTap: (Position) -> Void
    let onSwipe: (Direction) -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let cellSize = side / CGFloat(max(puzzle.width, puzzle.height))
            let padding = max(18, side * 0.045)

            ZStack {
                BoardAura(theme: theme)

                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(theme.boardFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .stroke(theme.panelStroke, lineWidth: 1)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(theme.tileLine, lineWidth: 1)
                            .padding(6)
                    }
                    .shadow(color: theme.tileShadow, radius: 34, y: 20)

                BoardGuideMarks(theme: theme)

                BoardGridLayer(
                    puzzle: puzzle,
                    placedMirrors: placedMirrors,
                    activated: activated,
                    broken: broken,
                    traversed: traversed,
                    mirroredFlash: mirroredFlash,
                    theme: theme,
                    highContrast: highContrast,
                    cellSize: cellSize,
                    padding: padding,
                    onTap: onTap
                )
                .equatable()

                TokenLayer(
                    tokenPosition: tokenPosition,
                    animationDuration: tokenAnimationDuration,
                    theme: theme,
                    highContrast: highContrast,
                    cellSize: cellSize,
                    padding: padding
                )
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onEnded { value in
                        guard let direction = resolveDirection(from: value.translation) else { return }
                        onSwipe(direction)
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func resolveDirection(from translation: CGSize) -> Direction? {
        let horizontal = translation.width
        let vertical = translation.height
        guard abs(horizontal) > 10 || abs(vertical) > 10 else { return nil }
        return abs(horizontal) > abs(vertical)
            ? (horizontal > 0 ? .right : .left)
            : (vertical > 0 ? .down : .up)
    }
}

private struct BoardGridLayer: View, Equatable {
    let puzzle: Puzzle
    let placedMirrors: [Position: TileKind]
    let activated: Set<Position>
    let broken: Set<Position>
    let traversed: Set<Position>
    let mirroredFlash: Position?
    let theme: ThemeDefinition
    let highContrast: Bool
    let cellSize: CGFloat
    let padding: CGFloat
    let onTap: (Position) -> Void

    nonisolated static func == (lhs: BoardGridLayer, rhs: BoardGridLayer) -> Bool {
        lhs.puzzle == rhs.puzzle &&
        lhs.placedMirrors == rhs.placedMirrors &&
        lhs.activated == rhs.activated &&
        lhs.broken == rhs.broken &&
        lhs.traversed == rhs.traversed &&
        lhs.mirroredFlash == rhs.mirroredFlash &&
        lhs.theme == rhs.theme &&
        lhs.highContrast == rhs.highContrast &&
        lhs.cellSize == rhs.cellSize &&
        lhs.padding == rhs.padding
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<puzzle.height, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<puzzle.width, id: \.self) { column in
                        let position = Position(row: row, column: column)

                        TileCellView(
                            position: position,
                            baseKind: puzzle.tile(at: position),
                            placedKind: placedMirrors[position],
                            isActivated: activated.contains(position),
                            isBroken: broken.contains(position),
                            isTraversed: traversed.contains(position),
                            isMirrorFlashing: mirroredFlash == position,
                            canPlaceMirror: puzzle.canPlaceMirror(at: position),
                            theme: theme,
                            highContrast: highContrast,
                            cellSize: cellSize
                        )
                        .equatable()
                        .frame(width: cellSize, height: cellSize)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onTap(position)
                        }
                    }
                }
            }
        }
        .padding(padding)
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

private struct TokenLayer: View {
    let tokenPosition: Position
    let animationDuration: Double
    let theme: ThemeDefinition
    let highContrast: Bool
    let cellSize: CGFloat
    let padding: CGFloat

    var body: some View {
        TokenView(theme: theme, highContrast: highContrast)
            .frame(width: cellSize * 0.56, height: cellSize * 0.56)
            .position(
                x: padding + cellSize * (CGFloat(tokenPosition.column) + 0.5),
                y: padding + cellSize * (CGFloat(tokenPosition.row) + 0.5)
            )
    }
}

private struct BoardAura: View {
    let theme: ThemeDefinition

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50, style: .continuous)
                .fill(theme.glow.opacity(0.07))
                .blur(radius: 30)
                .padding(-12)

            RoundedRectangle(cornerRadius: 50, style: .continuous)
                .stroke(theme.accentSoft.opacity(0.12), lineWidth: 1)
                .padding(-8)
        }
    }
}

private struct BoardGuideMarks: View {
    let theme: ThemeDefinition

    var body: some View {
        VStack {
            HStack {
                Capsule().fill(theme.tileLine).frame(width: 32, height: 1)
                Spacer()
                Capsule().fill(theme.tileLine).frame(width: 32, height: 1)
            }
            Spacer()
            HStack {
                Capsule().fill(theme.tileLine).frame(width: 32, height: 1)
                Spacer()
                Capsule().fill(theme.tileLine).frame(width: 32, height: 1)
            }
        }
        .padding(18)
    }
}

private struct TileCellView: View, Equatable {
    let position: Position
    let baseKind: TileKind
    let placedKind: TileKind?
    let isActivated: Bool
    let isBroken: Bool
    let isTraversed: Bool
    let isMirrorFlashing: Bool
    let canPlaceMirror: Bool
    let theme: ThemeDefinition
    let highContrast: Bool
    let cellSize: CGFloat

    var body: some View {
        let kind = placedKind ?? baseKind

        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tileBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(highContrast ? theme.textSecondary.opacity(0.75) : theme.tileLine, lineWidth: 0.8)
                }
                .shadow(color: theme.tileShadow.opacity(0.12), radius: 4, y: 2)

            if isTraversed {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.accentSoft.opacity(0.08))
                    .padding(8)
                    .blur(radius: 4)
            }

            switch kind {
            case .wall:
                WallGlyph(theme: theme, highContrast: highContrast)
            case .stop:
                StopGlyph(theme: theme)
            case .paint(let required):
                PaintGlyph(theme: theme, isActivated: isActivated, required: required)
            case .gate(let required):
                GateGlyph(theme: theme, isActivated: isActivated, required: required)
            case .mirrorSlash:
                MirrorGlyph(kind: .mirrorSlash, theme: theme, compact: isCompactCell)
            case .mirrorBackslash:
                MirrorGlyph(kind: .mirrorBackslash, theme: theme, compact: isCompactCell)
            case .oneWay(let direction):
                OneWayGlyph(direction: direction, theme: theme)
            case .rotatorClockwise:
                RotatorGlyph(theme: theme)
            case .breakable:
                BreakableGlyph(theme: theme, isBroken: isBroken)
            case .socket:
                SocketGlyph(theme: theme, placedKind: placedKind, canPlaceMirror: canPlaceMirror, compact: isCompactCell)
            case .empty:
                EmptyView()
            }

            if isActivated {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.accentSoft.opacity(0.07))
                    .blur(radius: 6)
            }

            if isMirrorFlashing {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.glow.opacity(0.2))
                    .blur(radius: 12)
            }
        }
        .padding(4.5)
    }

    private var isCompactCell: Bool {
        cellSize < 30
    }

    private var tileBackground: LinearGradient {
        let top = isActivated ? theme.accent.opacity(0.14) : Color.white.opacity(0.04)
        let bottom = isActivated ? theme.accentSoft.opacity(0.08) : Color.black.opacity(0.04)
        return LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct WallGlyph: View {
    let theme: ThemeDefinition
    let highContrast: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        theme.textPrimary.opacity(highContrast ? 0.52 : 0.28),
                        theme.textPrimary.opacity(highContrast ? 0.4 : 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 18, height: 6)
                    .offset(x: 8, y: 8)
            }
            .padding(6)
    }
}

private struct StopGlyph: View {
    let theme: ThemeDefinition

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(theme.accent.opacity(0.1))
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(theme.accent.opacity(0.9), lineWidth: 1.8)
            Circle()
                .fill(theme.accent.opacity(0.6))
                .frame(width: 7, height: 7)
        }
        .padding(11)
    }
}

private struct PaintGlyph: View {
    let theme: ThemeDefinition
    let isActivated: Bool
    let required: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill((isActivated ? theme.accentSoft : theme.accent).opacity(required ? 0.88 : 0.42))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
            .overlay {
                Image(systemName: isActivated ? "sparkle" : "circle.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.white.opacity(isActivated ? 0.85 : 0.42))
            }
            .padding(11)
    }
}

private struct GateGlyph: View {
    let theme: ThemeDefinition
    let isActivated: Bool
    let required: Bool

    var body: some View {
        ZStack {
            Capsule()
                .stroke(
                    (isActivated ? theme.success : theme.glow).opacity(required ? 0.95 : 0.55),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                )
            HStack(spacing: 6) {
                Capsule().frame(width: 2)
                Capsule().frame(width: 2)
                Capsule().frame(width: 2)
            }
            .foregroundStyle((isActivated ? theme.success : theme.glow).opacity(0.72))
        }
        .padding(12)
    }
}

private struct MirrorGlyph: View {
    let kind: TileKind
    let theme: ThemeDefinition
    let compact: Bool

    var body: some View {
        GeometryReader { proxy in
            let inset: CGFloat = compact ? proxy.size.width * 0.14 : proxy.size.width * 0.18
            let plateInset: CGFloat = compact ? proxy.size.width * 0.06 : proxy.size.width * 0.1
            let strokeWidth = compact ? max(3.8, proxy.size.width * 0.12) : max(3.4, proxy.size.width * 0.09)
            let anchorSize = max(7, proxy.size.width * 0.14)
            let edgeInset = compact ? max(4, proxy.size.width * 0.1) : max(5, proxy.size.width * 0.12)

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.textPrimary.opacity(0.12),
                                highlightColor.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(highlightColor.opacity(0.38), lineWidth: 1.1)
                    }
                    .padding(plateInset)

                mirrorOrientationGlow

                anchorDots(size: proxy.size, dotSize: anchorSize, inset: edgeInset)

                Path { path in
                    switch kind {
                    case .mirrorSlash:
                        path.move(to: CGPoint(x: proxy.size.width - inset, y: inset))
                        path.addLine(to: CGPoint(x: inset, y: proxy.size.height - inset))
                    default:
                        path.move(to: CGPoint(x: inset, y: inset))
                        path.addLine(to: CGPoint(x: proxy.size.width - inset, y: proxy.size.height - inset))
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [theme.textPrimary.opacity(0.98), highlightColor.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .shadow(color: highlightColor.opacity(0.22), radius: 5)
            }
        }
        .padding(compact ? 2.5 : 6)
    }

    private var highlightColor: Color {
        switch kind {
        case .mirrorSlash:
            theme.glow
        case .mirrorBackslash:
            theme.accentSoft
        default:
            theme.glow
        }
    }

    @ViewBuilder
    private var mirrorOrientationGlow: some View {
        if kind == .mirrorSlash {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [highlightColor.opacity(0.26), .clear, highlightColor.opacity(0.18)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .rotationEffect(.degrees(-45))
                .blur(radius: 8)
                .padding(12)
        } else {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [highlightColor.opacity(0.22), .clear, highlightColor.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(45))
                .blur(radius: 8)
                .padding(12)
        }
    }

    @ViewBuilder
    private func anchorDots(size: CGSize, dotSize: CGFloat, inset: CGFloat) -> some View {
        if kind == .mirrorSlash {
            Circle()
                .fill(highlightColor.opacity(0.92))
                .frame(width: dotSize, height: dotSize)
                .position(x: size.width - inset, y: inset)
            Circle()
                .fill(highlightColor.opacity(0.72))
                .frame(width: dotSize, height: dotSize)
                .position(x: inset, y: size.height - inset)
        } else {
            Circle()
                .fill(highlightColor.opacity(0.92))
                .frame(width: dotSize, height: dotSize)
                .position(x: inset, y: inset)
            Circle()
                .fill(highlightColor.opacity(0.72))
                .frame(width: dotSize, height: dotSize)
                .position(x: size.width - inset, y: size.height - inset)
        }
    }
}

private struct OneWayGlyph: View {
    let direction: Direction
    let theme: ThemeDefinition

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.accent.opacity(0.75), lineWidth: 1.6)
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(theme.accent)
        }
        .padding(11)
    }

    private var systemImage: String {
        switch direction {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .left: "arrow.left"
        case .right: "arrow.right"
        }
    }
}

private struct RotatorGlyph: View {
    let theme: ThemeDefinition

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.glow.opacity(0.85), lineWidth: 1.8)
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.glow)
        }
        .padding(11)
    }
}

private struct BreakableGlyph: View {
    let theme: ThemeDefinition
    let isBroken: Bool

    var body: some View {
        ZStack {
            DiamondShape()
                .stroke(theme.glow.opacity(isBroken ? 0.3 : 0.8), lineWidth: 1.5)
            CrackShape()
                .stroke(theme.glow.opacity(isBroken ? 0.42 : 0.68), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
            if isBroken {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.glow.opacity(0.45))
            }
        }
        .padding(13)
    }
}

private struct SocketGlyph: View {
    let theme: ThemeDefinition
    let placedKind: TileKind?
    let canPlaceMirror: Bool
    let compact: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    theme.textSecondary.opacity(compact ? 0.44 : 0.35),
                    style: StrokeStyle(lineWidth: compact ? 1.7 : 1.4, dash: [5, 4])
                )
            if placedKind != nil {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.glow.opacity(compact ? 0.1 : 0.06))
            }
            if let placedKind {
                MirrorGlyph(kind: placedKind, theme: theme, compact: compact)
                    .padding(compact ? 0 : 1)
            } else if canPlaceMirror {
                ZStack {
                    Circle()
                        .fill(theme.accentSoft.opacity(compact ? 0.12 : 0.08))
                        .frame(width: compact ? 24 : 28, height: compact ? 24 : 28)
                    Capsule().fill(theme.textSecondary.opacity(compact ? 0.44 : 0.32)).frame(width: compact ? 16 : 18, height: compact ? 2.1 : 1.8)
                    Capsule().fill(theme.textSecondary.opacity(compact ? 0.44 : 0.32)).frame(width: compact ? 2.1 : 1.8, height: compact ? 16 : 18)
                    Circle()
                        .fill(theme.textSecondary.opacity(compact ? 0.38 : 0.28))
                        .frame(width: compact ? 8 : 7, height: compact ? 8 : 7)
                }
            }
        }
        .padding(compact ? 5 : 8)
    }
}

private struct TokenView: View {
    let theme: ThemeDefinition
    let highContrast: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.glow.opacity(0.22))
                .blur(radius: 12)
                .scaleEffect(1.45)

            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.textPrimary,
                            highContrast ? theme.accent : theme.accentSoft,
                            theme.glow.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(45))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                        .rotationEffect(.degrees(45))
                }
                .shadow(color: theme.glow.opacity(0.5), radius: 16, y: 5)

            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 8, height: 8)
                .offset(x: -6, y: -6)
        }
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct CrackShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 3))
        path.addLine(to: CGPoint(x: rect.midX - 2, y: rect.midY - 2))
        path.addLine(to: CGPoint(x: rect.midX + 2, y: rect.midY + 1))
        path.addLine(to: CGPoint(x: rect.midX - 1, y: rect.maxY - 4))
        path.move(to: CGPoint(x: rect.midX - 1, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + 4, y: rect.midY + 3))
        return path
    }
}
