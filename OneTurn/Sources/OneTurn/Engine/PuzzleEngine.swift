import Foundation

struct SimulationStep: Hashable {
    var position: Position
    var direction: Direction
    var activated: Set<Position>
    var broken: Set<Position>
    var traversed: Set<Position>
    var mirroredPosition: Position?
}

struct SimulationResult: Hashable {
    enum EndReason: Hashable {
        case boundary
        case wall
        case stop
        case loopGuard
    }

    var steps: [SimulationStep]
    var solved: Bool
    var completionRatio: Double
    var activated: Set<Position>
    var broken: Set<Position>
    var traversed: Set<Position>
    var endPosition: Position
    var swipe: Direction
    var endReason: EndReason
    var placedMirrors: [Position: TileKind]
}

struct PuzzleEngine {
    private struct PreparedPuzzle {
        let tileMap: [Position: TileKind]
        let objectives: Set<Position>
        let placeablePositions: Set<Position>
    }

    func solvingConfigurations(for puzzle: Puzzle) -> [(direction: Direction, placedMirrors: [Position: TileKind])] {
        Direction.allCases.flatMap { direction in
            solvingPlacements(for: puzzle, swipe: direction).map { placement in
                (direction, placement)
            }
        }
    }

    func solvingDirections(for puzzle: Puzzle) -> [Direction] {
        Array(Set(solvingConfigurations(for: puzzle).map(\.direction)))
    }

    func simulate(
        puzzle: Puzzle,
        swipe: Direction,
        placedMirrors: [Position: TileKind] = [:]
    ) -> SimulationResult {
        let prepared = prepare(puzzle)
        var activated: Set<Position> = []
        var broken: Set<Position> = []
        var traversed: Set<Position> = [puzzle.startPosition]
        var steps: [SimulationStep] = []
        var current = puzzle.startPosition
        var direction = swipe
        var endReason: SimulationResult.EndReason = .boundary
        var loopGuard = Set<String>()

        for _ in 0..<(puzzle.width * puzzle.height * 8) {
            let next = current.moved(direction)
            if !puzzle.contains(next) {
                endReason = .boundary
                break
            }

            let nextTile = tile(at: next, prepared: prepared, placedMirrors: placedMirrors)
            if nextTile == .wall {
                endReason = .wall
                break
            }
            if case .oneWay(let allowed) = nextTile, direction != allowed {
                endReason = .wall
                break
            }

            current = next
            traversed.insert(current)

            var mirroredPosition: Position?
            let tile = tile(at: current, prepared: prepared, placedMirrors: placedMirrors)

            switch tile {
            case .paint(let required):
                if required { activated.insert(current) }
            case .gate(let required):
                if required { activated.insert(current) }
            case .breakable:
                broken.insert(current)
            case .mirrorSlash, .mirrorBackslash:
                direction = direction.reflected(by: tile)
                mirroredPosition = current
            case .rotatorClockwise:
                direction = direction.rotatedClockwise()
                mirroredPosition = current
            case .stop:
                steps.append(
                    SimulationStep(
                        position: current,
                        direction: direction,
                        activated: activated,
                        broken: broken,
                        traversed: traversed,
                        mirroredPosition: mirroredPosition
                    )
                )
                endReason = .stop
                let solved = prepared.objectives.isSubset(of: activated)
                return SimulationResult(
                    steps: steps,
                    solved: solved,
                    completionRatio: completionRatio(activated: activated, objectives: prepared.objectives),
                    activated: activated,
                    broken: broken,
                    traversed: traversed,
                    endPosition: current,
                    swipe: swipe,
                    endReason: endReason,
                    placedMirrors: placedMirrors
                )
            case .empty, .wall, .oneWay:
                break
            case .socket:
                break
            }

            let stateKey = "\(current.row),\(current.column),\(direction.rawValue),\(broken.count)"
            if loopGuard.contains(stateKey) {
                endReason = .loopGuard
                break
            }
            loopGuard.insert(stateKey)

            steps.append(
                SimulationStep(
                    position: current,
                    direction: direction,
                    activated: activated,
                    broken: broken,
                    traversed: traversed,
                    mirroredPosition: mirroredPosition
                )
            )
        }

        let solved = prepared.objectives.isSubset(of: activated)
        return SimulationResult(
            steps: steps,
            solved: solved,
            completionRatio: completionRatio(activated: activated, objectives: prepared.objectives),
            activated: activated,
            broken: broken,
            traversed: traversed,
            endPosition: current,
            swipe: swipe,
            endReason: endReason,
            placedMirrors: placedMirrors
        )
    }

    private func completionRatio(activated: Set<Position>, objectives: Set<Position>) -> Double {
        guard !objectives.isEmpty else { return 1 }
        return Double(activated.intersection(objectives).count) / Double(objectives.count)
    }

    private func prepare(_ puzzle: Puzzle) -> PreparedPuzzle {
        let tileMap = Dictionary(uniqueKeysWithValues: puzzle.tiles.map { ($0.position, $0.kind) })
        let objectives = Set(puzzle.tiles.compactMap { $0.kind.isObjective ? $0.position : nil })
        let placeablePositions = Set<Position>(
            (0..<puzzle.height).flatMap { row in
                (0..<puzzle.width).compactMap { column in
                    let position = Position(row: row, column: column)
                    guard position != puzzle.startPosition else { return nil }
                    let kind = tileMap[position] ?? .empty
                    return (kind == .empty || kind == .socket) ? position : nil
                }
            }
        )
        return PreparedPuzzle(tileMap: tileMap, objectives: objectives, placeablePositions: placeablePositions)
    }

    private func tile(at position: Position, prepared: PreparedPuzzle, placedMirrors: [Position: TileKind]) -> TileKind {
        placedMirrors[position] ?? prepared.tileMap[position] ?? .empty
    }

    private func solvingPlacements(for puzzle: Puzzle, swipe: Direction) -> [[Position: TileKind]] {
        struct SearchState: Hashable {
            var position: Position
            var direction: Direction
            var activated: [Position]
            var broken: [Position]
            var placedMirrors: [Position: TileKind]
        }

        let prepared = prepare(puzzle)
        var solutions = Set<[Position: TileKind]>()
        var visited = Set<SearchState>()

        func normalized(_ positions: Set<Position>) -> [Position] {
            positions.sorted {
                if $0.row == $1.row { return $0.column < $1.column }
                return $0.row < $1.row
            }
        }

        func search(
            current: Position,
            direction: Direction,
            activated: Set<Position>,
            broken: Set<Position>,
            placedMirrors: [Position: TileKind]
        ) {
            let state = SearchState(
                position: current,
                direction: direction,
                activated: normalized(activated),
                broken: normalized(broken),
                placedMirrors: placedMirrors
            )

            guard visited.insert(state).inserted else { return }

            let next = current.moved(direction)
            guard puzzle.contains(next) else {
                if prepared.objectives.isSubset(of: activated) {
                    solutions.insert(placedMirrors)
                }
                return
            }

            let baseTile = tile(at: next, prepared: prepared, placedMirrors: placedMirrors)
            guard baseTile != .wall else {
                if prepared.objectives.isSubset(of: activated) {
                    solutions.insert(placedMirrors)
                }
                return
            }
            if case .oneWay(let allowed) = baseTile, direction != allowed {
                if prepared.objectives.isSubset(of: activated) {
                    solutions.insert(placedMirrors)
                }
                return
            }

            var nextActivated = activated
            var nextBroken = broken

            switch baseTile {
            case .paint(let required):
                if required { nextActivated.insert(next) }
                search(
                    current: next,
                    direction: direction,
                    activated: nextActivated,
                    broken: nextBroken,
                    placedMirrors: placedMirrors
                )
            case .gate(let required):
                if required { nextActivated.insert(next) }
                search(
                    current: next,
                    direction: direction,
                    activated: nextActivated,
                    broken: nextBroken,
                    placedMirrors: placedMirrors
                )
            case .breakable:
                nextBroken.insert(next)
                search(
                    current: next,
                    direction: direction,
                    activated: nextActivated,
                    broken: nextBroken,
                    placedMirrors: placedMirrors
                )
            case .mirrorSlash, .mirrorBackslash:
                search(
                    current: next,
                    direction: direction.reflected(by: baseTile),
                    activated: nextActivated,
                    broken: nextBroken,
                    placedMirrors: placedMirrors
                )
            case .rotatorClockwise:
                search(
                    current: next,
                    direction: direction.rotatedClockwise(),
                    activated: nextActivated,
                    broken: nextBroken,
                    placedMirrors: placedMirrors
                )
            case .stop:
                if prepared.objectives.isSubset(of: nextActivated) {
                    solutions.insert(placedMirrors)
                }
            case .empty, .socket, .oneWay:
                search(
                    current: next,
                    direction: direction,
                    activated: nextActivated,
                    broken: nextBroken,
                    placedMirrors: placedMirrors
                )

                guard prepared.placeablePositions.contains(next), placedMirrors.count < puzzle.placeableMirrorLimit else {
                    return
                }

                for mirror in [TileKind.mirrorSlash, .mirrorBackslash] {
                    var updatedMirrors = placedMirrors
                    updatedMirrors[next] = mirror
                    search(
                        current: next,
                        direction: direction.reflected(by: mirror),
                        activated: nextActivated,
                        broken: nextBroken,
                        placedMirrors: updatedMirrors
                    )
                }
            case .wall:
                break
            }
        }

        search(
            current: puzzle.startPosition,
            direction: swipe,
            activated: [],
            broken: [],
            placedMirrors: [:]
        )

        return Array(solutions)
    }
}
