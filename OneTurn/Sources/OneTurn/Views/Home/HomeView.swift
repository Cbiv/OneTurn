import SwiftUI

struct HomeView: View {
    @Bindable var appModel: AppModel

    private var theme: ThemeDefinition {
        ThemeDefinition.definition(for: appModel.currentTheme())
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    heroSection
                        .padding(.top, 20)

                    let daily = appModel.dailyDescriptor()
                    Button {
                        appModel.screen = .daily
                    } label: {
                        HomeCard(
                            theme: theme,
                            title: "Daily Puzzle",
                            subtitle: "Puzzle #\(daily.puzzleNumber)",
                            detail: appModel.progress.hasSolvedDaily(on: daily.dateKey)
                                ? "Solved today. Replay without affecting streak."
                                : "Streak \(appModel.progress.currentStreak). One shared composition for today."
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        appModel.screen = .studio
                    } label: {
                        HomeCard(
                            theme: theme,
                            title: "Studio Mode",
                            subtitle: "Crafted packs",
                            detail: "Move through hand-framed puzzle rooms with quiet hint nudges."
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        appModel.screen = .endless
                    } label: {
                        HomeCard(
                            theme: theme,
                            title: "Endless Mode",
                            subtitle: "Momentum run",
                            detail: "Current high score: \(appModel.progress.endlessHighScore)"
                        )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 12) {
                        SmallHomeButton(theme: theme, title: "Stats", systemImage: "chart.bar") {
                            appModel.screen = .stats
                        }
                        SmallHomeButton(theme: theme, title: "Theme", systemImage: "circle.lefthalf.filled") {
                            appModel.presentThemes()
                        }
                        SmallHomeButton(theme: theme, title: "Settings", systemImage: "slider.horizontal.3") {
                            appModel.screen = .settings
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
                .padding(20)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var heroSection: some View {
        GlassCard(theme: theme) {
            VStack(alignment: .leading, spacing: 14) {
                Text("ONE TURN")
                    .font(.caption)
                    .textCase(.uppercase)
                    .tracking(4.4)
                    .foregroundStyle(theme.textSecondary)

                Text("A gallery puzzle\nfor one gesture.")
                    .font(.system(size: 44, weight: .bold, design: .serif))
                    .foregroundStyle(theme.textPrimary)

                HStack(spacing: 12) {
                    HeroBadge(theme: theme, title: appModel.progress.selectedTheme.displayName, icon: "circle.lefthalf.filled")
                    HeroBadge(theme: theme, title: "Streak \(appModel.progress.currentStreak)", icon: "flame")
                }

                Text("See the board. Swipe once. Let the composition finish itself.")
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct HomeCard: View {
    let theme: ThemeDefinition
    let title: String
    let subtitle: String
    let detail: String

    var body: some View {
        GlassCard(theme: theme) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .textCase(.uppercase)
                    .tracking(2.4)
                    .foregroundStyle(theme.accent)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)

                HStack {
                    Capsule()
                        .fill(theme.accentSoft.opacity(0.6))
                        .frame(width: 42, height: 5)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SmallHomeButton: View {
    let theme: ThemeDefinition
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.footnote.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 78)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(theme.tileLine, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct HeroBadge: View {
    let theme: ThemeDefinition
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.boardFill, in: Capsule())
    }
}
