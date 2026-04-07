import SwiftUI

struct StudioModeView: View {
    @Bindable var appModel: AppModel
    @State private var selectedPack: PuzzlePack?
    @State private var selectedPuzzle: Puzzle?
    @State private var session: GameSession?

    private var theme: ThemeDefinition {
        ThemeDefinition.definition(for: appModel.currentTheme())
    }

    var body: some View {
        if let selectedPack, let selectedPuzzle {
            let activeSession = session ?? makeSession(for: selectedPuzzle)

            PuzzlePlayView(
                appModel: appModel,
                session: activeSession,
                heading: selectedPack.title,
                subheading: selectedPuzzle.title,
                hintEnabled: true,
                onHome: {
                    self.selectedPuzzle = nil
                    self.selectedPack = nil
                    self.session = nil
                    appModel.screen = .home
                },
                onSolved: { _, time in
                    appModel.markStudioSolved(packID: selectedPack.id, puzzle: selectedPuzzle, solveTime: time)
                }
            ) {
                    Text("Pack progress \(solvedCount(in: selectedPack))/\(selectedPack.puzzles.count)")
                        .font(.footnote)
                        .foregroundStyle(theme.textSecondary)
            }
            .onAppear {
                if session == nil {
                    session = activeSession
                }
            }
        } else if let selectedPack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    topBar(title: selectedPack.title)

                    Text(selectedPack.subtitle)
                        .font(.footnote)
                        .foregroundStyle(theme.textSecondary)

                    ForEach(selectedPack.puzzles) { puzzle in
                        Button {
                            selectedPuzzle = puzzle
                            session = makeSession(for: puzzle)
                        } label: {
                            GlassCard(theme: theme) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(puzzle.title)
                                            .font(.headline)
                                            .foregroundStyle(theme.textPrimary)
                                        Text(puzzle.difficulty.label)
                                            .font(.caption)
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: isSolved(puzzle, in: selectedPack) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isSolved(puzzle, in: selectedPack) ? theme.success : theme.textSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    topBar(title: "Studio Mode")

                    ForEach(appModel.library.studioPacks) { pack in
                        Button {
                            selectedPack = pack
                        } label: {
                            GlassCard(theme: theme) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(pack.title)
                                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                                        .foregroundStyle(theme.textPrimary)
                                    Text(pack.subtitle)
                                        .font(.footnote)
                                        .foregroundStyle(theme.textSecondary)
                                    ProgressView(value: Double(solvedCount(in: pack)), total: Double(pack.puzzles.count))
                                        .tint(theme.accent)
                                    Text("\(solvedCount(in: pack))/\(pack.puzzles.count) solved")
                                        .font(.caption)
                                        .foregroundStyle(theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
    }

    private func topBar(title: String) -> some View {
        HStack {
            Button {
                selectedPuzzle = nil
                selectedPack = nil
                session = nil
                appModel.screen = .home
            } label: {
                Image(systemName: "house")
                    .font(.headline)
            }
            .buttonStyle(OrbButtonStyle(theme: theme))

            Text(title)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Spacer()
        }
        .padding(.top, 20)
    }

    private func solvedCount(in pack: PuzzlePack) -> Int {
        appModel.progress.studioSolved[pack.id]?.count ?? 0
    }

    private func isSolved(_ puzzle: Puzzle, in pack: PuzzlePack) -> Bool {
        appModel.progress.studioSolved[pack.id]?.contains(puzzle.id) ?? false
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
}
