import SwiftUI

struct PuzzlePlayView<Footer: View>: View {
    @Bindable var appModel: AppModel
    @Bindable var session: GameSession
    let heading: String
    let subheading: String
    let hintEnabled: Bool
    let onHome: () -> Void
    let onSolved: (Direction, TimeInterval) -> Void
    let footer: Footer
    @State private var showHint = false

    init(
        appModel: AppModel,
        session: GameSession,
        heading: String,
        subheading: String,
        hintEnabled: Bool,
        onHome: @escaping () -> Void,
        onSolved: @escaping (Direction, TimeInterval) -> Void,
        @ViewBuilder footer: () -> Footer
    ) {
        self.appModel = appModel
        self.session = session
        self.heading = heading
        self.subheading = subheading
        self.hintEnabled = hintEnabled
        self.onHome = onHome
        self.onSolved = onSolved
        self.footer = footer()
    }

    private var theme: ThemeDefinition {
        ThemeDefinition.definition(for: appModel.currentTheme(for: session.puzzle))
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = GameplayLayoutMetrics(proxy: proxy, hasOutcome: session.outcome != nil)
            let compactHeight = metrics.compactHeight
            let verticalSpacing: CGFloat = compactHeight ? 14 : 20
            let titleSize: CGFloat = compactHeight ? 28 : 34

            ScrollView(showsIndicators: false) {
                VStack(spacing: verticalSpacing) {
                    HStack {
                        Button(action: onHome) {
                            Image(systemName: "house")
                                .font(.headline)
                        }
                        .buttonStyle(OrbButtonStyle(theme: theme))
                        .accessibilityLabel("Return home")

                        Spacer()

                        Text(heading)
                            .font(.caption2)
                            .textCase(.uppercase)
                            .tracking(3)
                            .foregroundStyle(theme.textSecondary)

                        Spacer()

                        Button(action: session.restart) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.headline)
                        }
                        .buttonStyle(OrbButtonStyle(theme: theme))
                        .accessibilityLabel("Restart puzzle")
                    }

                    VStack(spacing: compactHeight ? 6 : 10) {
                        Text(subheading)
                            .font(.system(size: titleSize, weight: .semibold, design: .serif))
                            .foregroundStyle(theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(session.puzzle.difficulty.label)
                            .font(.caption2)
                            .textCase(.uppercase)
                            .tracking(2.4)
                            .foregroundStyle(theme.accent)
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: compactHeight ? 14 : 18) {
                            PuzzleBoardView(
                                puzzle: session.puzzle,
                                placedMirrors: session.placedMirrors,
                                activated: session.activated,
                                broken: session.broken,
                                traversed: session.traversed,
                                mirroredFlash: session.mirroredFlash,
                                tokenPosition: session.tokenPosition,
                                tokenAnimationDuration: session.tokenAnimationDuration,
                                theme: theme,
                                highContrast: appModel.progress.settings.highContrast,
                                onTap: session.cyclePlacement(at:)
                            ) { direction in
                                session.commitSwipe(direction) { solved, swipe, time in
                                    if solved {
                                        onSolved(swipe, time)
                                    }
                                }
                            }
                            .frame(maxWidth: metrics.boardSide)
                            .frame(height: metrics.boardSide)

                            StatusChipsRow(
                                placeableMirrorLimit: session.puzzle.placeableMirrorLimit,
                                mirrorsRemaining: session.mirrorsRemaining,
                                outcomeLabel: session.outcomeLabel,
                                statusIcon: session.statusIcon,
                                theme: theme,
                                compactWidth: proxy.size.width < 390
                            )

                            if hintEnabled {
                                Button(showHint ? "Hide hint" : "Hint") {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showHint.toggle()
                                    }
                                }
                                .buttonStyle(.borderless)
                                .foregroundStyle(theme.accent)
                            }

                            if showHint, let hint = session.puzzle.hintText {
                                Text(hint)
                                    .font(.footnote)
                                    .foregroundStyle(theme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }

                            footer
                        }
                    }
                    .frame(maxWidth: .infinity)

                    if let outcome = session.outcome {
                        GlassCard(theme: theme) {
                            VStack(spacing: 12) {
                                Text(outcome == .solved ? "Solved" : (session.completionRatio >= 0.66 ? "Almost" : "Not Yet"))
                                    .font(.system(size: compactHeight ? 26 : 30, weight: .semibold, design: .serif))
                                    .foregroundStyle(outcome == .solved ? theme.success : theme.failure)
                                Text(outcome == .solved ? "One motion. Everything lit." : nearMissCopy)
                                    .font(.footnote)
                                    .foregroundStyle(theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                HStack(spacing: 12) {
                                    StatChip(label: "Time", value: session.elapsedTime.formattedTenths, theme: theme)
                                    if let direction = session.solvedDirection {
                                        StatChip(label: "Swipe", value: direction.symbol, theme: theme)
                                    }
                                    StatChip(label: "Progress", value: "\(Int(session.completionRatio * 100))%", theme: theme)
                                }
                            }
                        }
                    } else {
                        Text(session.puzzle.placeableMirrorLimit > 0 ? "Arrange the board. Commit to one line." : "Inspect the board. Commit to one line.")
                            .font(.footnote)
                            .foregroundStyle(theme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(theme.cardFill, in: Capsule())
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.top, metrics.contentTopPadding)
                .padding(.bottom, metrics.contentBottomPadding)
                .foregroundStyle(theme.textPrimary)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaPadding(.top, metrics.safeAreaTopInset)
            .safeAreaPadding(.bottom, metrics.safeAreaBottomInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var nearMissCopy: String {
        session.completionRatio >= 0.66
            ? "You almost had the composition. One mark stayed dark."
            : "The board stayed quiet. Reset and try a cleaner line."
    }
}

private struct GameplayLayoutMetrics {
    let compactHeight: Bool
    let boardSide: CGFloat
    let horizontalPadding: CGFloat
    let safeAreaTopInset: CGFloat
    let safeAreaBottomInset: CGFloat
    let contentTopPadding: CGFloat
    let contentBottomPadding: CGFloat

    init(proxy: GeometryProxy, hasOutcome: Bool) {
        let safeTop = proxy.safeAreaInsets.top
        let safeBottom = proxy.safeAreaInsets.bottom
        let width = proxy.size.width
        let height = proxy.size.height

        compactHeight = height < 780
        horizontalPadding = width < 390 ? 16 : 20
        safeAreaTopInset = max(12, safeTop + 8)
        safeAreaBottomInset = max(12, safeBottom + 8)
        contentTopPadding = compactHeight ? 8 : 12
        contentBottomPadding = compactHeight ? 12 : 16

        let reservedHeight: CGFloat = compactHeight
            ? (hasOutcome ? 360 : 320)
            : (hasOutcome ? 400 : 350)
        let availableHeight = max(
            260,
            height - safeAreaTopInset - safeAreaBottomInset - contentTopPadding - contentBottomPadding - reservedHeight
        )
        let availableWidth = width - (horizontalPadding * 2) - 24

        boardSide = min(max(availableHeight, 260), max(availableWidth, 260), 560)
    }
}

private struct StatusChipsRow: View {
    let placeableMirrorLimit: Int
    let mirrorsRemaining: Int
    let outcomeLabel: String
    let statusIcon: String
    let theme: ThemeDefinition
    let compactWidth: Bool

    var body: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 14) {
                chips
            }
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    chip("One swipe only", systemImage: "hand.draw")
                    if placeableMirrorLimit > 0 {
                        chip("\(mirrorsRemaining) placements", systemImage: "circle.grid.2x2")
                    }
                }
                chip(outcomeLabel, systemImage: statusIcon)
            }
        }
        .font(compactWidth ? .caption : .footnote)
        .foregroundStyle(theme.textSecondary)
    }

    @ViewBuilder
    private var chips: some View {
        chip("One swipe only", systemImage: "hand.draw")
        if placeableMirrorLimit > 0 {
            chip("\(mirrorsRemaining) placements", systemImage: "circle.grid.2x2")
        }
        Spacer(minLength: 0)
        chip(outcomeLabel, systemImage: statusIcon)
    }

    private func chip(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.boardFill, in: Capsule())
    }
}

private struct StatChip: View {
    let label: String
    let value: String
    let theme: ThemeDefinition

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .textCase(.uppercase)
                .tracking(1.8)
                .foregroundStyle(theme.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.boardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.tileLine, lineWidth: 1)
                )
        )
    }
}

private extension GameSession {
    var outcomeLabel: String {
        if let outcome {
            return outcome == .solved ? "Solved" : "Retry ready"
        }
        return hasPlayed ? "Settling" : "Awaiting swipe"
    }

    var statusIcon: String {
        if let outcome {
            return outcome == .solved ? "sparkles" : "moon.stars"
        }
        return hasPlayed ? "hourglass" : "hand.draw"
    }
}

private extension TimeInterval {
    var formattedTenths: String {
        String(format: "%.1fs", self)
    }
}
