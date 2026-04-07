import SwiftUI

struct StatsView: View {
    @Bindable var appModel: AppModel

    private var theme: ThemeDefinition {
        ThemeDefinition.definition(for: appModel.currentTheme())
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Button {
                            appModel.screen = .home
                        } label: {
                            Image(systemName: "house")
                                .font(.headline)
                        }
                        .buttonStyle(OrbButtonStyle(theme: theme))

                        Text("Stats")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                    }
                    .padding(.top, 20)

                    GlassCard(theme: theme) {
                        VStack(spacing: 14) {
                            StatsRow(label: "Daily streak", value: "\(appModel.progress.currentStreak)", theme: theme)
                            StatsRow(label: "Longest streak", value: "\(appModel.progress.longestStreak)", theme: theme)
                            StatsRow(label: "Solved total", value: "\(appModel.progress.totalPuzzlesSolved)", theme: theme)
                            StatsRow(label: "Best endless", value: "\(appModel.progress.endlessHighScore)", theme: theme)
                            StatsRow(label: "Best chain", value: "\(appModel.progress.endlessBestChain)", theme: theme)
                            StatsRow(label: "Endless average", value: appModel.progress.averageEndlessScore().map { String(format: "%.0f", $0) } ?? "n/a", theme: theme)
                            StatsRow(label: "Perfect clears", value: "\(appModel.progress.perfectClears)", theme: theme)
                            StatsRow(label: "Average daily", value: appModel.progress.averageDailySolveTime().map { String(format: "%.1fs", $0) } ?? "n/a", theme: theme)
                            StatsRow(label: "Best daily", value: appModel.progress.bestDailySolveTime().map { String(format: "%.1fs", $0) } ?? "n/a", theme: theme)
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 14) {
                            StatsRow(label: "Launches", value: "\(appModel.betaStatus.launchCount)", theme: theme)
                            StatsRow(label: "Crash-free beta", value: "\(Int((appModel.betaStatus.crashFreeRate * 100).rounded()))%", theme: theme)
                            StatsRow(label: "Unexpected closes", value: "\(appModel.betaStatus.unexpectedCloseCount)", theme: theme)
                            StatsRow(label: "Mirror placements", value: "\(appModel.analyticsSnapshot.eventCounts["mirror_placed", default: 0])", theme: theme)
                            StatsRow(label: "Swipes committed", value: "\(appModel.analyticsSnapshot.eventCounts["swipe_committed", default: 0])", theme: theme)
                            StatsRow(label: "Daily solves tracked", value: "\(appModel.analyticsSnapshot.eventCounts["daily_solved", default: 0])", theme: theme)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct StatsRow: View {
    let label: String
    let value: String
    let theme: ThemeDefinition

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(theme.textPrimary)
                .fontWeight(.semibold)
        }
        .font(.body)
    }
}
