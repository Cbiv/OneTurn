import SwiftUI

struct ThemePickerView: View {
    @Bindable var appModel: AppModel

    private var activeTheme: ThemeDefinition {
        ThemeDefinition.definition(for: appModel.currentTheme())
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Button {
                        appModel.screen = .home
                    } label: {
                        Image(systemName: "house")
                            .font(.headline)
                    }
                    .buttonStyle(OrbButtonStyle(theme: activeTheme))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Themes")
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(activeTheme.textPrimary)
                        Text("Choose the room the puzzle lives in.")
                            .font(.footnote)
                            .foregroundStyle(activeTheme.textSecondary)
                    }
                }
                .padding(.top, 20)

                ForEach(ThemeChoice.allCases, id: \.self) { choice in
                    let previewTheme = ThemeDefinition.definition(for: choice)

                    Button {
                        appModel.selectTheme(choice)
                    } label: {
                        GlassCard(theme: previewTheme) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(choice.displayName)
                                            .font(.system(size: 30, weight: .semibold, design: .serif))
                                            .foregroundStyle(previewTheme.textPrimary)
                                        Text(themeDescription(for: choice))
                                            .font(.footnote)
                                            .foregroundStyle(previewTheme.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: appModel.progress.selectedTheme == choice ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(appModel.progress.selectedTheme == choice ? previewTheme.success : previewTheme.textSecondary)
                                }

                                HStack(spacing: 10) {
                                    ThemeSwatch(color: previewTheme.accent)
                                    ThemeSwatch(color: previewTheme.accentSoft)
                                    ThemeSwatch(color: previewTheme.glow)
                                    Spacer()
                                    ThemeMiniBoard(theme: previewTheme)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(PillActionButtonStyle(theme: previewTheme))
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func themeDescription(for choice: ThemeChoice) -> String {
        switch choice {
        case .nocturne:
            "Midnight stone, warm brass, and a hush of gallery light."
        case .paperBloom:
            "Soft paper, ink lines, and a calm editorial glow."
        case .electricQuiet:
            "Deep plum shadows with mint and peach reflections."
        }
    }
}

private struct ThemeSwatch: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 22, height: 22)
    }
}

private struct ThemeMiniBoard: View {
    let theme: ThemeDefinition

    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(theme.boardFill)
            .frame(width: 92, height: 92)
            .overlay {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        MiniTile(theme: theme, fill: theme.textPrimary.opacity(0.08))
                        MiniTile(theme: theme, fill: theme.accent.opacity(0.42))
                        MiniTile(theme: theme, fill: theme.textPrimary.opacity(0.08))
                    }
                    HStack(spacing: 6) {
                        MiniTile(theme: theme, fill: theme.textPrimary.opacity(0.08))
                        MiniTile(theme: theme, fill: theme.accentSoft.opacity(0.42))
                        MiniTile(theme: theme, fill: theme.textPrimary.opacity(0.08))
                    }
                    HStack(spacing: 6) {
                        MiniTile(theme: theme, fill: theme.textPrimary.opacity(0.08))
                        MiniTile(theme: theme, fill: theme.glow.opacity(0.32))
                        MiniTile(theme: theme, fill: theme.textPrimary.opacity(0.08))
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(theme.tileLine, lineWidth: 1)
            }
    }
}

private struct MiniTile: View {
    let theme: ThemeDefinition
    let fill: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(fill)
            .frame(width: 18, height: 18)
    }
}
