import SwiftUI

struct DailyPuzzleView: View {
    @Bindable var appModel: AppModel
    @State private var session: GameSession?
    @State private var shareText = ""
    @State private var solvedToday = false

    var body: some View {
        let descriptor = appModel.dailyDescriptor()
        Group {
            if let session {
                PuzzlePlayView(
                    appModel: appModel,
                    session: session,
                    heading: "Daily Puzzle",
                    subheading: "#\(descriptor.puzzleNumber)",
                    hintEnabled: appModel.progress.settings.allowDailyHints,
                    onHome: { appModel.screen = .home },
                    onSolved: { swipe, solveTime in
                        solvedToday = true
                        appModel.markDailySolved(descriptor, swipe: swipe, solveTime: solveTime)
                        shareText = appModel.shareText(for: descriptor, swipe: swipe)
                    }
                ) {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                StatLine(label: "Streak", value: "\(appModel.progress.currentStreak)", theme: theme)
                                StatLine(label: "Today", value: solvedToday ? "First Clear" : (appModel.progress.hasSolvedDaily(on: descriptor.dateKey) ? "Replay" : "Unsolved"), theme: theme)
                            }

                            if let best = appModel.progress.bestDailySolveTime() {
                                StatLine(label: "Best Daily", value: String(format: "%.1fs", best), theme: theme)
                            }

                            if !shareText.isEmpty {
                                ShareLink(item: shareText) {
                                    Label("Share Result", systemImage: "square.and.arrow.up")
                                        .foregroundStyle(theme.textPrimary)
                                }
                                .buttonStyle(PillActionButtonStyle(theme: theme, accent: theme.accent))
                            }
                        }
                }
            } else {
                ProgressView()
                    .tint(theme.textPrimary)
            }
        }
        .task(id: descriptor.dateKey) {
            session = makeSession(for: descriptor)
            solvedToday = appModel.progress.hasSolvedDaily(on: descriptor.dateKey)
            shareText = solvedToday
                ? appModel.shareText(for: descriptor, swipe: descriptor.puzzle.validSolutionDirection)
                : ""
        }
    }

    private var theme: ThemeDefinition {
        ThemeDefinition.definition(for: appModel.currentTheme())
    }

    private func makeSession(for descriptor: DailyPuzzleDescriptor) -> GameSession {
        GameSession(
            puzzle: descriptor.puzzle,
            engine: appModel.engine,
            settings: appModel.progress.settings,
            haptics: appModel.haptics,
            sound: appModel.sound,
            analytics: appModel.analytics
        )
    }
}

struct StatLine: View {
    let label: String
    let value: String
    let theme: ThemeDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .textCase(.uppercase)
                .tracking(1.6)
                .foregroundStyle(theme.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(theme.boardFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
