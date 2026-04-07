import Foundation

struct PuzzleLibrary {
    static let shared = PuzzleLibrary()

    let onboarding: [Puzzle]
    let studioPacks: [PuzzlePack]
    let dailyPool: [Puzzle]
    let endlessPool: [Puzzle]
    let endlessBands: [[Puzzle]]

    init() {
        let base = PuzzleLibrary.makeBasePuzzles()
        onboarding = Self.validated([
            base[0].transformed(id: "onboard-1", title: "Swipe once", mode: .onboarding),
            base[1].transformed(id: "onboard-2", title: "Light every mark", mode: .onboarding),
            base[2].transformed(id: "onboard-3", title: "Use the board", mode: .onboarding)
        ])

        let firstLight = PuzzlePack(
            id: "first-light",
            title: "First Light",
            subtitle: "Fourteen soft starts",
            puzzles: Self.makeVariants(from: Array(base.prefix(5)), count: 14, difficulty: .obvious, titlePrefix: "First Light")
        )
        let reflection = PuzzlePack(
            id: "reflection",
            title: "Reflection",
            subtitle: "Mirrors with intent",
            puzzles: Self.makeVariants(from: Array(base[2...7]), count: 20, difficulty: .clean, titlePrefix: "Reflection")
        )
        let throughline = PuzzlePack(
            id: "throughline",
            title: "Throughline",
            subtitle: "Paint and gates in one breath",
            puzzles: Self.makeVariants(from: Array(base[5...10]), count: 22, difficulty: .clever, titlePrefix: "Throughline")
        )
        let brutalism = PuzzlePack(
            id: "quiet-brutalism",
            title: "Quiet Brutalism",
            subtitle: "Small devious frames",
            puzzles: Self.makeVariants(from: Array(base[8...13]), count: 20, difficulty: .tricky, titlePrefix: "Quiet Brutalism")
        )
        let turnstile = PuzzlePack(
            id: "turnstile",
            title: "Turnstile",
            subtitle: "One-way channels",
            puzzles: Self.makeVariants(from: [base[13], base[16]], count: 18, difficulty: .tricky, titlePrefix: "Turnstile")
        )
        let clockwork = PuzzlePack(
            id: "clockwork",
            title: "Clockwork",
            subtitle: "Turns that arrive for you",
            puzzles: Self.makeVariants(from: [base[16], base[13]], count: 18, difficulty: .elegantBrutal, titlePrefix: "Clockwork")
        )

        let packs = [
            firstLight.validated(),
            reflection.validated(),
            throughline.validated(),
            brutalism.validated(),
            turnstile.validated(),
            clockwork.validated()
        ]
        studioPacks = packs

        let planningSeeds = Self.makePlanningPuzzles()
        let dailySeeds = Self.makeDailySeeds(base: base, planningSeeds: planningSeeds)
        dailyPool = Self.makeDailyPuzzles(from: dailySeeds, targetCount: 96)

        let bandASeeds = Array(packs[0].puzzles.prefix(10)) + Array(base.prefix(4))
        let bandBSeeds = Array(packs[0].puzzles.suffix(6)) + Array(packs[1].puzzles.prefix(10)) + Array(base[3...7])
        let bandCSeeds = Array(packs[1].puzzles.suffix(10)) + Array(packs[2].puzzles.prefix(10)) + Array(packs[4].puzzles.prefix(6)) + Array(planningSeeds.prefix(3))
        let bandDSeeds = Array(packs[2].puzzles.suffix(10)) + Array(packs[3].puzzles.prefix(10)) + Array(packs[4].puzzles.suffix(8)) + Array(packs[5].puzzles.prefix(6)) + Array(planningSeeds[2...6])
        let bandESeeds = Array(packs[3].puzzles.suffix(10)) + Array(packs[5].puzzles) + Array(planningSeeds.suffix(7))

        let bandA = Self.makeEndlessBand(from: bandASeeds, targetCount: 24, band: "a", difficulty: .obvious, parTime: 6)
        let bandB = Self.makeEndlessBand(from: bandBSeeds, targetCount: 26, band: "b", difficulty: .clean, parTime: 9)
        let bandC = Self.makeEndlessBand(from: bandCSeeds, targetCount: 30, band: "c", difficulty: .clever, parTime: 12)
        let bandD = Self.makeEndlessBand(from: bandDSeeds, targetCount: 32, band: "d", difficulty: .tricky, parTime: 16)
        let bandE = Self.makeEndlessBand(from: bandESeeds, targetCount: 36, band: "e", difficulty: .elegantBrutal, parTime: 22)

        endlessBands = [bandA, bandB, bandC, bandD, bandE]

        endlessPool = endlessBands.flatMap { $0 }
    }

    private static func makeVariants(from seeds: [Puzzle], count: Int, difficulty: DifficultyBand, titlePrefix: String) -> [Puzzle] {
        validated((0..<count).map { index in
            let seed = seeds[index % seeds.count]
            let turns = index % 4
            let flipped = index % 3 == 0
            var puzzle = seed.transformed(
                id: "\(seed.id)-\(index)",
                title: "\(titlePrefix) \(index + 1)",
                rotateClockwise: turns,
                flipHorizontally: flipped,
                mode: .studio
            )
            puzzle.difficulty = difficulty
            puzzle.parTime = difficulty == .obvious ? 5 : difficulty == .clean ? 8 : difficulty == .clever ? 12 : 16
            return puzzle
        })
    }

    private static func makeEndlessBand(
        from seeds: [Puzzle],
        targetCount: Int,
        band: String,
        difficulty: DifficultyBand,
        parTime: TimeInterval
    ) -> [Puzzle] {
        validated((0..<(targetCount * 2)).map { index in
            let seed = seeds[index % seeds.count]
            let turns = (index + (index / max(seeds.count, 1))) % 4
            let flipped = index.isMultiple(of: 2)
            var puzzle = seed.transformed(
                id: "\(seed.id)-endless-\(band)-\(index)",
                title: seed.title,
                rotateClockwise: turns,
                flipHorizontally: flipped,
                mode: .endless
            )
            puzzle.difficulty = difficulty
            puzzle.parTime = parTime
            return puzzle
        })
        .prefixing(targetCount)
    }

    private static func makeBasePuzzles() -> [Puzzle] {
        [
            puzzle(
                id: "seed-001",
                title: "Straight Glow",
                width: 5,
                height: 5,
                start: .init(row: 2, column: 1),
                solution: .right,
                difficulty: .obvious,
                hint: "The first line is enough.",
                tiles: [
                    tile(0, 0, .wall), tile(0, 1, .wall), tile(0, 2, .wall), tile(0, 3, .wall), tile(0, 4, .wall),
                    tile(1, 0, .wall), tile(1, 4, .wall),
                    tile(2, 0, .wall), tile(2, 3, .paint(required: true)), tile(2, 4, .wall),
                    tile(3, 0, .wall), tile(3, 4, .wall),
                    tile(4, 0, .wall), tile(4, 1, .wall), tile(4, 2, .wall), tile(4, 3, .wall), tile(4, 4, .wall)
                ]
            ),
            puzzle(
                id: "seed-002",
                title: "Quiet Marks",
                width: 5,
                height: 5,
                start: .init(row: 3, column: 2),
                solution: .up,
                difficulty: .obvious,
                hint: "You are trying to touch everything.",
                tiles: [
                    tile(0, 0, .wall), tile(0, 1, .wall), tile(0, 2, .wall), tile(0, 3, .wall), tile(0, 4, .wall),
                    tile(1, 0, .wall), tile(1, 2, .gate(required: true)), tile(1, 4, .wall),
                    tile(2, 0, .wall), tile(2, 2, .gate(required: true)), tile(2, 4, .wall),
                    tile(3, 0, .wall), tile(3, 4, .wall),
                    tile(4, 0, .wall), tile(4, 1, .wall), tile(4, 2, .wall), tile(4, 3, .wall), tile(4, 4, .wall)
                ]
            ),
            puzzle(
                id: "seed-003",
                title: "Bend of Light",
                width: 5,
                height: 5,
                start: .init(row: 3, column: 1),
                solution: .up,
                difficulty: .clean,
                hint: "Think about where you need to bend.",
                tiles: [
                    tile(0, 0, .wall), tile(0, 1, .wall), tile(0, 2, .wall), tile(0, 3, .wall), tile(0, 4, .wall),
                    tile(1, 0, .wall), tile(1, 4, .wall),
                    tile(2, 0, .wall), tile(2, 1, .mirrorSlash), tile(2, 3, .paint(required: true)), tile(2, 4, .wall),
                    tile(3, 0, .wall), tile(3, 4, .wall),
                    tile(4, 0, .wall), tile(4, 1, .wall), tile(4, 2, .wall), tile(4, 3, .wall), tile(4, 4, .wall)
                ]
            ),
            puzzle(
                id: "seed-004",
                title: "Stop Thought",
                width: 6,
                height: 6,
                start: .init(row: 4, column: 1),
                solution: .up,
                difficulty: .clean,
                hint: "Not every stop is a failure.",
                tiles: perimeter(6, 6) + [
                    tile(3, 1, .gate(required: true)),
                    tile(2, 1, .mirrorSlash),
                    tile(2, 3, .paint(required: true)),
                    tile(2, 4, .stop)
                ]
            ),
            puzzle(
                id: "seed-005",
                title: "Quiet Fracture",
                width: 6,
                height: 6,
                start: .init(row: 1, column: 1),
                solution: .right,
                difficulty: .clean,
                hint: "Passing through can still matter.",
                tiles: perimeter(6, 6) + [
                    tile(1, 2, .breakable),
                    tile(1, 3, .paint(required: true)),
                    tile(1, 4, .mirrorBackslash),
                    tile(3, 4, .gate(required: true))
                ]
            ),
            puzzle(
                id: "seed-006",
                title: "Double Quiet",
                width: 6,
                height: 6,
                start: .init(row: 4, column: 4),
                solution: .left,
                difficulty: .clever,
                hint: "The first line is not the final line.",
                tiles: perimeter(6, 6) + [
                    tile(4, 3, .gate(required: true)),
                    tile(4, 2, .mirrorBackslash),
                    tile(2, 2, .paint(required: true))
                ]
            ),
            puzzle(
                id: "seed-007",
                title: "Paper Corridor",
                width: 6,
                height: 6,
                start: .init(row: 4, column: 1),
                solution: .up,
                difficulty: .clever,
                hint: "Touch, turn, continue.",
                tiles: perimeter(6, 6) + [
                    tile(3, 1, .mirrorSlash),
                    tile(3, 2, .paint(required: true)),
                    tile(3, 3, .gate(required: true)),
                    tile(4, 3, .stop)
                ]
            ),
            puzzle(
                id: "seed-008",
                title: "Folded Glass",
                width: 7,
                height: 7,
                start: .init(row: 5, column: 1),
                solution: .up,
                difficulty: .tricky,
                hint: "You need both corners of the thought.",
                tiles: perimeter(7, 7) + [
                    tile(2, 3, .paint(required: true)),
                    tile(2, 1, .mirrorSlash),
                    tile(2, 5, .mirrorBackslash),
                    tile(5, 5, .gate(required: true))
                ]
            ),
            puzzle(
                id: "seed-009",
                title: "Quiet Brutal",
                width: 6,
                height: 6,
                start: .init(row: 1, column: 4),
                solution: .down,
                difficulty: .tricky,
                hint: "A straight line can still be elaborate.",
                tiles: perimeter(6, 6) + [
                    tile(2, 4, .gate(required: true)),
                    tile(3, 4, .mirrorSlash),
                    tile(3, 1, .paint(required: true))
                ]
            ),
            puzzle(
                id: "seed-010",
                title: "Split Thinking",
                width: 7,
                height: 7,
                start: .init(row: 5, column: 5),
                solution: .left,
                difficulty: .tricky,
                hint: "You are composing one sentence.",
                tiles: perimeter(7, 7) + [
                    tile(5, 3, .gate(required: true)),
                    tile(5, 2, .mirrorBackslash),
                    tile(4, 2, .paint(required: true)),
                    tile(3, 2, .mirrorSlash)
                ]
            ),
            puzzle(
                id: "seed-011",
                title: "Thin Air",
                width: 6,
                height: 6,
                start: .init(row: 4, column: 4),
                solution: .left,
                difficulty: .elegantBrutal,
                hint: "The shortest move is not small.",
                tiles: perimeter(6, 6) + [
                    tile(4, 3, .paint(required: true)),
                    tile(4, 2, .mirrorBackslash),
                    tile(2, 2, .gate(required: true))
                ]
            ),
            puzzle(
                id: "seed-012",
                title: "Museum Turn",
                width: 6,
                height: 6,
                start: .init(row: 4, column: 4),
                solution: .up,
                difficulty: .elegantBrutal,
                hint: "Begin where the shape feels wrong.",
                tiles: perimeter(6, 6) + [
                    tile(3, 4, .gate(required: true)),
                    tile(2, 4, .mirrorBackslash),
                    tile(2, 2, .paint(required: true))
                ]
            ),
            puzzle(
                id: "seed-013",
                title: "Gallery Silence",
                width: 7,
                height: 7,
                start: .init(row: 1, column: 1),
                solution: .right,
                difficulty: .elegantBrutal,
                hint: "There is only one graceful collision.",
                tiles: perimeter(7, 7) + [
                    tile(1, 5, .mirrorBackslash),
                    tile(3, 5, .gate(required: true)),
                    tile(5, 5, .paint(required: true))
                ]
            ),
            puzzle(
                id: "seed-014",
                title: "Turnstile Study",
                width: 7,
                height: 7,
                start: .init(row: 5, column: 1),
                solution: .up,
                difficulty: .tricky,
                hint: "Some entries only welcome one direction.",
                tiles: perimeter(7, 7) + [
                    tile(3, 1, .oneWay(.up)),
                    tile(2, 1, .mirrorSlash),
                    tile(2, 3, .paint(required: true)),
                    tile(2, 5, .gate(required: true))
                ]
            ),
            puzzle(
                id: "seed-015",
                title: "Clockwise Hush",
                width: 7,
                height: 7,
                start: .init(row: 5, column: 1),
                solution: .up,
                difficulty: .tricky,
                hint: "One turn is given to you.",
                tiles: perimeter(7, 7) + [
                    tile(2, 1, .rotatorClockwise),
                    tile(2, 3, .paint(required: true)),
                    tile(2, 5, .gate(required: true))
                ]
            ),
            puzzle(
                id: "seed-016",
                title: "Directed Drift",
                width: 7,
                height: 7,
                start: .init(row: 5, column: 5),
                solution: .left,
                difficulty: .elegantBrutal,
                hint: "The board allows only the clean arrival.",
                tiles: perimeter(7, 7) + [
                    tile(5, 3, .rotatorClockwise),
                    tile(3, 3, .oneWay(.up)),
                    tile(2, 3, .gate(required: true)),
                    tile(2, 5, .paint(required: true))
                ]
            ),
            puzzle(
                id: "seed-017",
                title: "Clockwork Gallery",
                width: 8,
                height: 8,
                start: .init(row: 6, column: 1),
                solution: .up,
                difficulty: .elegantBrutal,
                hint: "A borrowed turn can still be precise.",
                tiles: perimeter(8, 8) + [
                    tile(4, 1, .oneWay(.up)),
                    tile(2, 1, .rotatorClockwise),
                    tile(2, 4, .paint(required: true)),
                    tile(2, 6, .mirrorBackslash),
                    tile(5, 6, .gate(required: true))
                ]
            )
        ]
    }

    private static func makePlanningPuzzles() -> [Puzzle] {
        validated([
            puzzle(
                id: "plan-002",
                title: "Held Angle",
                width: 7,
                height: 7,
                start: .init(row: 5, column: 1),
                solution: .up,
                placedMirrors: [Position(row: 2, column: 1): .mirrorSlash],
                difficulty: .clever,
                hint: "The board waits for your intervention.",
                placeableMirrorLimit: 1,
                tiles: perimeter(7, 7) + [
                    tile(2, 3, .gate(required: true)),
                    tile(2, 5, .paint(required: true))
                ]
            ),
            puzzle(
                id: "plan-003",
                title: "Two Quiet Hands",
                width: 7,
                height: 7,
                start: .init(row: 5, column: 1),
                solution: .up,
                placedMirrors: [Position(row: 2, column: 1): .mirrorSlash, Position(row: 2, column: 5): .mirrorBackslash],
                difficulty: .tricky,
                hint: "Build the corridor, then trust it.",
                placeableMirrorLimit: 2,
                tiles: perimeter(7, 7) + [
                    tile(2, 3, .paint(required: true)),
                    tile(5, 5, .gate(required: true))
                ]
            ),
            puzzle(
                id: "plan-004",
                title: "Placement Theory",
                width: 7,
                height: 7,
                start: .init(row: 1, column: 5),
                solution: .down,
                placedMirrors: [Position(row: 4, column: 5): .mirrorSlash, Position(row: 4, column: 1): .mirrorBackslash],
                difficulty: .tricky,
                hint: "The route is authored before it begins.",
                placeableMirrorLimit: 2,
                tiles: perimeter(7, 7) + [
                    tile(2, 1, .gate(required: true)),
                    tile(2, 5, .gate(required: true)),
                    tile(4, 3, .paint(required: true)),
                    tile(3, 3, .stop)
                ]
            ),
            puzzle(
                id: "plan-005",
                title: "Curated Loop",
                width: 11,
                height: 11,
                start: .init(row: 9, column: 1),
                solution: .up,
                placedMirrors: [
                    Position(row: 2, column: 1): .mirrorSlash,
                    Position(row: 2, column: 9): .mirrorBackslash,
                    Position(row: 8, column: 9): .mirrorSlash,
                    Position(row: 8, column: 3): .mirrorBackslash,
                    Position(row: 4, column: 3): .mirrorSlash,
                    Position(row: 4, column: 7): .mirrorBackslash
                ],
                difficulty: .elegantBrutal,
                hint: "You are placing the sentence marks.",
                placeableMirrorLimit: 6,
                tiles: chamber(
                    width: 11,
                    height: 11,
                    open: column(1, 2...9) +
                        row(2, 1...9) +
                        column(9, 2...8) +
                        row(8, 3...9) +
                        column(3, 4...8) +
                        row(4, 3...7) +
                        column(7, 4...9),
                    features: [
                        tile(6, 1, .gate(required: true)),
                        tile(2, 5, .paint(required: true)),
                        tile(5, 9, .gate(required: true)),
                        tile(8, 6, .paint(required: true)),
                        tile(6, 3, .gate(required: true)),
                        tile(4, 5, .paint(required: true)),
                        tile(7, 7, .gate(required: true)),
                        tile(9, 7, .stop)
                    ]
                )
            ),
            puzzle(
                id: "plan-006",
                title: "Gallery Mechanism",
                width: 11,
                height: 11,
                start: .init(row: 1, column: 1),
                solution: .right,
                placedMirrors: [
                    Position(row: 1, column: 8): .mirrorBackslash,
                    Position(row: 9, column: 8): .mirrorSlash,
                    Position(row: 9, column: 2): .mirrorBackslash,
                    Position(row: 3, column: 2): .mirrorSlash,
                    Position(row: 3, column: 6): .mirrorBackslash,
                    Position(row: 7, column: 6): .mirrorSlash
                ],
                difficulty: .elegantBrutal,
                hint: "The hard part happens before motion.",
                placeableMirrorLimit: 6,
                tiles: chamber(
                    width: 11,
                    height: 11,
                    open: row(1, 1...8) +
                        column(8, 1...9) +
                        row(9, 2...8) +
                        column(2, 3...9) +
                        row(3, 2...6) +
                        column(6, 3...7) +
                        row(7, 1...6),
                    features: [
                        tile(1, 4, .paint(required: true)),
                        tile(5, 8, .gate(required: true)),
                        tile(9, 5, .paint(required: true)),
                        tile(6, 2, .gate(required: true)),
                        tile(3, 4, .paint(required: true)),
                        tile(5, 6, .gate(required: true)),
                        tile(7, 3, .paint(required: true))
                    ]
                )
            ),
            puzzle(
                id: "plan-007",
                title: "Quiet Architecture",
                width: 12,
                height: 12,
                start: .init(row: 10, column: 2),
                solution: .up,
                placedMirrors: [
                    Position(row: 2, column: 2): .mirrorSlash,
                    Position(row: 2, column: 9): .mirrorBackslash,
                    Position(row: 6, column: 9): .mirrorSlash,
                    Position(row: 6, column: 4): .mirrorBackslash,
                    Position(row: 3, column: 4): .mirrorSlash,
                    Position(row: 3, column: 7): .mirrorBackslash
                ],
                difficulty: .elegantBrutal,
                hint: "A longer route needs perfect punctuation.",
                placeableMirrorLimit: 6,
                tiles: chamber(
                    width: 12,
                    height: 12,
                    open: column(2, 2...10) +
                        row(2, 2...9) +
                        column(9, 2...6) +
                        row(6, 4...9) +
                        column(4, 3...6) +
                        row(3, 4...7) +
                        column(7, 3...9),
                    features: [
                        tile(8, 2, .gate(required: true)),
                        tile(2, 5, .paint(required: true)),
                        tile(4, 9, .gate(required: true)),
                        tile(6, 6, .paint(required: true)),
                        tile(4, 4, .gate(required: true)),
                        tile(3, 6, .paint(required: true)),
                        tile(8, 7, .gate(required: true)),
                        tile(9, 7, .stop)
                    ]
                )
            ),
            puzzle(
                id: "plan-008",
                title: "Long Museum",
                width: 12,
                height: 12,
                start: .init(row: 10, column: 1),
                solution: .up,
                placedMirrors: [
                    Position(row: 2, column: 1): .mirrorSlash,
                    Position(row: 2, column: 8): .mirrorBackslash,
                    Position(row: 9, column: 8): .mirrorSlash,
                    Position(row: 9, column: 4): .mirrorBackslash,
                    Position(row: 5, column: 4): .mirrorSlash,
                    Position(row: 5, column: 10): .mirrorBackslash
                ],
                difficulty: .elegantBrutal,
                hint: "The route is longer than it looks.",
                placeableMirrorLimit: 6,
                tiles: chamber(
                    width: 12,
                    height: 12,
                    open: column(1, 2...10) +
                        row(2, 1...8) +
                        column(8, 2...9) +
                        row(9, 4...8) +
                        column(4, 5...9) +
                        row(5, 4...10) +
                        column(10, 5...10),
                    features: [
                        tile(8, 1, .gate(required: true)),
                        tile(2, 4, .paint(required: true)),
                        tile(6, 8, .gate(required: true)),
                        tile(9, 6, .paint(required: true)),
                        tile(7, 4, .gate(required: true)),
                        tile(5, 7, .paint(required: true)),
                        tile(8, 10, .gate(required: true)),
                        tile(10, 10, .stop)
                    ]
                )
            ),
            puzzle(
                id: "plan-010",
                title: "Curator's Line",
                width: 13,
                height: 13,
                start: .init(row: 11, column: 2),
                solution: .up,
                placedMirrors: [
                    Position(row: 2, column: 2): .mirrorSlash,
                    Position(row: 2, column: 10): .mirrorBackslash,
                    Position(row: 7, column: 10): .mirrorSlash,
                    Position(row: 7, column: 5): .mirrorBackslash,
                    Position(row: 4, column: 5): .mirrorSlash,
                    Position(row: 4, column: 8): .mirrorBackslash
                ],
                difficulty: .elegantBrutal,
                hint: "A hard board can still feel composed.",
                placeableMirrorLimit: 6,
                tiles: chamber(
                    width: 13,
                    height: 13,
                    open: column(2, 2...11) +
                        row(2, 2...10) +
                        column(10, 2...7) +
                        row(7, 5...10) +
                        column(5, 4...7) +
                        row(4, 5...8) +
                        column(8, 4...10),
                    features: [
                        tile(9, 2, .gate(required: true)),
                        tile(2, 6, .paint(required: true)),
                        tile(5, 10, .gate(required: true)),
                        tile(7, 7, .paint(required: true)),
                        tile(5, 5, .gate(required: true)),
                        tile(4, 7, .paint(required: true)),
                        tile(9, 8, .gate(required: true)),
                        tile(10, 8, .stop)
                    ]
                )
            ),
            puzzle(
                id: "plan-011",
                title: "Velvet Switchback",
                width: 13,
                height: 13,
                start: .init(row: 11, column: 1),
                solution: .up,
                placedMirrors: [
                    Position(row: 2, column: 1): .mirrorSlash,
                    Position(row: 2, column: 9): .mirrorBackslash,
                    Position(row: 10, column: 9): .mirrorSlash,
                    Position(row: 10, column: 4): .mirrorBackslash,
                    Position(row: 5, column: 4): .mirrorSlash,
                    Position(row: 5, column: 11): .mirrorBackslash
                ],
                difficulty: .elegantBrutal,
                hint: "The route folds farther than the eye expects.",
                placeableMirrorLimit: 6,
                tiles: chamber(
                    width: 13,
                    height: 13,
                    open: column(1, 2...11) +
                        row(2, 1...9) +
                        column(9, 2...10) +
                        row(10, 4...9) +
                        column(4, 5...10) +
                        row(5, 4...11) +
                        column(11, 5...10),
                    features: [
                        tile(8, 1, .gate(required: true)),
                        tile(2, 4, .paint(required: true)),
                        tile(6, 9, .gate(required: true)),
                        tile(10, 6, .paint(required: true)),
                        tile(7, 4, .gate(required: true)),
                        tile(5, 8, .paint(required: true)),
                        tile(8, 11, .gate(required: true)),
                        tile(10, 11, .stop)
                    ]
                )
            ),
            puzzle(
                id: "plan-012",
                title: "Turning Chamber",
                width: 13,
                height: 13,
                start: .init(row: 11, column: 2),
                solution: .up,
                placedMirrors: [
                    Position(row: 2, column: 2): .mirrorSlash,
                    Position(row: 2, column: 10): .mirrorBackslash,
                    Position(row: 8, column: 10): .mirrorSlash,
                    Position(row: 8, column: 5): .mirrorBackslash,
                    Position(row: 4, column: 5): .mirrorSlash,
                    Position(row: 4, column: 8): .mirrorBackslash
                ],
                difficulty: .elegantBrutal,
                hint: "A borrowed turn still has to be earned.",
                placeableMirrorLimit: 6,
                tiles: chamber(
                    width: 13,
                    height: 13,
                    open: column(2, 2...11) +
                        row(2, 2...10) +
                        column(10, 2...8) +
                        row(8, 5...10) +
                        column(5, 4...8) +
                        row(4, 5...8) +
                        column(8, 4...10),
                    features: [
                        tile(9, 2, .gate(required: true)),
                        tile(2, 6, .paint(required: true)),
                        tile(6, 10, .rotatorClockwise),
                        tile(8, 7, .paint(required: true)),
                        tile(6, 5, .gate(required: true)),
                        tile(4, 7, .paint(required: true)),
                        tile(9, 8, .oneWay(.down)),
                        tile(10, 8, .stop)
                    ]
                )
            ),
            puzzle(
                id: "plan-013",
                title: "Arrow Gallery",
                width: 14,
                height: 14,
                start: .init(row: 12, column: 2),
                solution: .up,
                placedMirrors: [
                    Position(row: 2, column: 2): .mirrorSlash,
                    Position(row: 2, column: 11): .mirrorBackslash,
                    Position(row: 11, column: 11): .mirrorSlash,
                    Position(row: 11, column: 5): .mirrorBackslash,
                    Position(row: 6, column: 5): .mirrorSlash,
                    Position(row: 6, column: 9): .mirrorBackslash
                ],
                difficulty: .elegantBrutal,
                hint: "Permission matters as much as placement.",
                placeableMirrorLimit: 6,
                tiles: chamber(
                    width: 14,
                    height: 14,
                    open: column(2, 2...12) +
                        row(2, 2...11) +
                        column(11, 2...11) +
                        row(11, 5...11) +
                        column(5, 6...11) +
                        row(6, 5...9) +
                        column(9, 6...10),
                    features: [
                        tile(9, 2, .gate(required: true)),
                        tile(2, 6, .paint(required: true)),
                        tile(7, 11, .oneWay(.down)),
                        tile(11, 8, .paint(required: true)),
                        tile(8, 5, .gate(required: true)),
                        tile(6, 7, .paint(required: true)),
                        tile(9, 9, .gate(required: true)),
                        tile(10, 9, .stop)
                    ]
                )
            ),
            puzzle(
                id: "plan-014",
                title: "Quiet Engine",
                width: 14,
                height: 14,
                start: .init(row: 12, column: 1),
                solution: .up,
                placedMirrors: [
                    Position(row: 2, column: 1): .mirrorSlash,
                    Position(row: 2, column: 10): .mirrorBackslash,
                    Position(row: 11, column: 10): .mirrorSlash,
                    Position(row: 11, column: 4): .mirrorBackslash,
                    Position(row: 5, column: 4): .mirrorSlash,
                    Position(row: 5, column: 12): .mirrorBackslash
                ],
                difficulty: .elegantBrutal,
                hint: "The path asks for one last machine turn.",
                placeableMirrorLimit: 6,
                tiles: chamber(
                    width: 14,
                    height: 14,
                    open: column(1, 2...12) +
                        row(2, 1...10) +
                        column(10, 2...11) +
                        row(11, 4...10) +
                        column(4, 5...11) +
                        row(5, 4...12) +
                        column(12, 5...11),
                    features: [
                        tile(9, 1, .gate(required: true)),
                        tile(2, 5, .paint(required: true)),
                        tile(7, 10, .gate(required: true)),
                        tile(11, 7, .paint(required: true)),
                        tile(7, 4, .gate(required: true)),
                        tile(5, 9, .paint(required: true)),
                        tile(9, 12, .rotatorClockwise),
                        tile(11, 12, .stop)
                    ]
                )
            )
        ])
    }

    private static func makeDailySeeds(base: [Puzzle], planningSeeds: [Puzzle]) -> [Puzzle] {
        let brutalPlanningSeeds = planningSeeds.filter { $0.placeableMirrorLimit >= 6 }
        return validated(brutalPlanningSeeds)
    }

    private static func makeDailyPuzzles(from seeds: [Puzzle], targetCount: Int) -> [Puzzle] {
        let engine = PuzzleEngine()
        let candidates = validated(
            seeds.flatMap { seed in
                (0..<4).flatMap { turns in
                    [false, true].map { flipped in
                        var puzzle = seed.transformed(
                            id: "daily-hard-\(seed.id)-r\(turns)-f\(flipped ? 1 : 0)",
                            title: seed.title,
                            rotateClockwise: turns,
                            flipHorizontally: flipped,
                            mode: .daily
                        )
                        puzzle.difficulty = .elegantBrutal
                        puzzle.parTime = 42
                        return puzzle
                    }
                }
            }
        )

        let ranked = candidates
            .compactMap { puzzle -> (Puzzle, Int)? in
                guard qualifiesForDaily(puzzle, engine: engine) else { return nil }
                return (puzzle, dailyDifficultyScore(for: puzzle, engine: engine))
            }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.id < rhs.0.id
                }
                return lhs.1 > rhs.1
            }
            .map(\.0)

        let pool = ranked.isEmpty ? candidates : ranked
        return Array(pool.prefix(min(targetCount, pool.count))).enumerated().map { index, puzzle in
            var renamed = puzzle
            renamed.title = "Daily Composition \(index + 1)"
            return renamed
        }
    }

    private static func qualifiesForDaily(_ puzzle: Puzzle, engine: PuzzleEngine) -> Bool {
        guard puzzle.placeableMirrorLimit >= 6 else { return false }
        let result = engine.simulate(
            puzzle: puzzle,
            swipe: puzzle.validSolutionDirection,
            placedMirrors: puzzle.validPlacedMirrors
        )

        let objectives = puzzle.objectiveTiles.count
        let traversed = result.steps.count
        return objectives >= 6 && traversed >= 14
    }

    private static func dailyDifficultyScore(for puzzle: Puzzle, engine: PuzzleEngine) -> Int {
        let result = engine.simulate(
            puzzle: puzzle,
            swipe: puzzle.validSolutionDirection,
            placedMirrors: puzzle.validPlacedMirrors
        )

        let objectives = puzzle.objectiveTiles.count
        let mirrors = puzzle.validPlacedMirrors.count
        let reflections = result.steps.filter { $0.mirroredPosition != nil }.count
        let boardArea = puzzle.width * puzzle.height
        return (objectives * 30) + (mirrors * 24) + (reflections * 20) + (result.steps.count * 6) + boardArea
    }

    private static func planningVersion(of puzzle: Puzzle, id: String, title: String, hint: String) -> Puzzle {
        let mirrors = Dictionary(uniqueKeysWithValues: puzzle.tiles.compactMap { tile in
            tile.kind.isMirror ? (tile.position, tile.kind) : nil
        })

        let strippedTiles = puzzle.tiles.filter { !$0.kind.isMirror }

        return Puzzle(
            id: id,
            title: title,
            width: puzzle.width,
            height: puzzle.height,
            tiles: strippedTiles,
            startPosition: puzzle.startPosition,
            validSolutionDirection: puzzle.validSolutionDirection,
            validPlacedMirrors: mirrors,
            difficulty: .elegantBrutal,
            modeType: .daily,
            themeOverride: nil,
            parTime: 28,
            hintText: hint,
            placeableMirrorLimit: mirrors.count
        )
    }

    fileprivate static func validated(_ puzzles: [Puzzle]) -> [Puzzle] {
        let engine = PuzzleEngine()
        return puzzles.compactMap { puzzle in
            let configurations = engine.solvingConfigurations(for: puzzle)
            guard configurations.count == 1, let configuration = configurations.first else {
                return nil
            }

            var validated = puzzle
            validated.validSolutionDirection = configuration.direction
            validated.validPlacedMirrors = configuration.placedMirrors
            return validated
        }
    }

    private static func puzzle(
        id: String,
        title: String,
        width: Int,
        height: Int,
        start: Position,
        solution: Direction,
        placedMirrors: [Position: TileKind] = [:],
        difficulty: DifficultyBand,
        hint: String,
        placeableMirrorLimit: Int = 0,
        tiles: [Tile]
    ) -> Puzzle {
        Puzzle(
            id: id,
            title: title,
            width: width,
            height: height,
            tiles: tiles,
            startPosition: start,
            validSolutionDirection: solution,
            validPlacedMirrors: placedMirrors,
            difficulty: difficulty,
            modeType: .studio,
            themeOverride: nil,
            parTime: nil,
            hintText: hint,
            placeableMirrorLimit: placeableMirrorLimit
        )
    }

    private static func tile(_ row: Int, _ column: Int, _ kind: TileKind) -> Tile {
        Tile(position: Position(row: row, column: column), kind: kind)
    }

    private static func row(_ row: Int, _ columns: ClosedRange<Int>) -> [Position] {
        columns.map { Position(row: row, column: $0) }
    }

    private static func column(_ column: Int, _ rows: ClosedRange<Int>) -> [Position] {
        rows.map { Position(row: $0, column: column) }
    }

    private static func chamber(width: Int, height: Int, open: [Position], features: [Tile]) -> [Tile] {
        let openSet = Set(open)
        let featurePositions = Set(features.map(\.position))
        var tiles = perimeter(width, height)

        for row in 1..<(height - 1) {
            for column in 1..<(width - 1) {
                let position = Position(row: row, column: column)
                guard !openSet.contains(position), !featurePositions.contains(position) else { continue }
                tiles.append(Tile(position: position, kind: .wall))
            }
        }

        tiles.append(contentsOf: features)
        return tiles
    }

    private static func perimeter(_ width: Int, _ height: Int) -> [Tile] {
        var tiles: [Tile] = []
        for row in 0..<height {
            for column in 0..<width {
                if row == 0 || row == height - 1 || column == 0 || column == width - 1 {
                    tiles.append(Tile(position: Position(row: row, column: column), kind: .wall))
                }
            }
        }
        return tiles
    }

    func endlessPuzzle(for runIndex: Int) -> Puzzle {
        let bandIndex: Int
        switch runIndex {
        case 0..<4:
            bandIndex = 0
        case 4..<8:
            bandIndex = 1
        case 8..<13:
            bandIndex = 2
        case 13..<19:
            bandIndex = 3
        default:
            bandIndex = 4
        }

        let band = endlessBands[min(bandIndex, endlessBands.count - 1)]
        return band[runIndex % band.count]
    }
}

private extension PuzzlePack {
    func validated() -> PuzzlePack {
        PuzzlePack(id: id, title: title, subtitle: subtitle, puzzles: PuzzleLibrary.validated(puzzles))
    }
}

private extension Array {
    func prefixing(_ count: Int) -> [Element] {
        Array(prefix(count))
    }
}
