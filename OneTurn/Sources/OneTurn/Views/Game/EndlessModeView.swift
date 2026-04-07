import SwiftUI

struct EndlessModeView: View {
    @Bindable var appModel: AppModel
    @State private var runIndex = 0
    @State private var score = 0
    @State private var chain = 0
    @State private var failed = false
    @State private var runFinalized = false
    @State private var session: GameSession?

    var body: some View {
        Group {
            if let session {
                PuzzlePlayView(
                    appModel: appModel,
                    session: session,
                    heading: "Endless Mode",
                    subheading: "Score \(score)",
                    hintEnabled: false,
                    onHome: {
                        finalizeRunIfNeeded()
                        appModel.screen = .home
                    },
                    onSolved: { _, solveTime in
                        chain += 1
                        score += appModel.registerEndlessSolve(chain: chain, solveTime: solveTime, puzzle: session.puzzle)
                        runIndex += 1
                        failed = false
                        self.session = makeSession(for: puzzleForCurrentRun())
                    }
                ) {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                StatLine(label: "Score", value: "\(score)", theme: theme)
                                StatLine(label: "Best", value: "\(appModel.progress.endlessHighScore)", theme: theme)
                            }
                            HStack(spacing: 12) {
                                StatLine(label: "Chain", value: "\(chain)", theme: theme)
                                StatLine(label: "Best Chain", value: "\(appModel.progress.endlessBestChain)", theme: theme)
                            }
                            if failed {
                                HStack(spacing: 12) {
                                    Button("Restart Run", action: restartRun)
                                        .buttonStyle(PillActionButtonStyle(theme: theme, accent: theme.accent))
                                    Button("Home") {
                                        appModel.screen = .home
                                    }
                                    .buttonStyle(PillActionButtonStyle(theme: theme))
                                }
                            }
                        }
                }
                .onChange(of: session.outcome) { _, outcome in
                    guard outcome == .failed else { return }
                    failed = true
                    finalizeRunIfNeeded()
                }
            } else {
                ProgressView()
                    .tint(theme.textPrimary)
            }
        }
        .task {
            if session == nil {
                session = makeSession(for: puzzleForCurrentRun())
            }
        }
    }

    private var theme: ThemeDefinition {
        ThemeDefinition.definition(for: appModel.currentTheme())
    }

    private func puzzleForCurrentRun() -> Puzzle {
        appModel.library.endlessPuzzle(for: runIndex)
    }

    private func makeSession(for puzzle: Puzzle) -> GameSession {
        GameSession(
            puzzle: puzzle,
            engine: appModel.engine,
            settings: appModel.progress.settings,
            haptics: appModel.haptics,
            sound: appModel.sound,
            analytics: appModel.analytics
        )
    }

    private func restartRun() {
        finalizeRunIfNeeded()
        score = 0
        chain = 0
        runIndex = 0
        failed = false
        runFinalized = false
        session = makeSession(for: puzzleForCurrentRun())
    }

    private func finalizeRunIfNeeded() {
        guard !runFinalized else { return }
        runFinalized = true
        appModel.finalizeEndlessRun(score: score, chain: chain)
    }
}
