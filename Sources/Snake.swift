//
//  Snake.swift
//  Snake
//
//  Created by Evren Sen on 2024-11-19.
//

import Dispatch

enum Direction {
    case up
    case left
    case down
    case right
}

enum Snake: Character {
    case head = "o"
    case body = "*"
}

@main
struct Main: ~Copyable {
    static func main() async {
        var terminal = Terminal()
        try! terminal.setup()

        signal(SIGINT, SIG_IGN)

        let game = Task {
            try? await run(&terminal)
        }

        let source = DispatchSource.makeSignalSource(
            signal: SIGINT, queue: .main)

        source.setEventHandler {
            game.cancel()
        }

        source.resume()
        await game.value
        terminal.cleanup()
        source.cancel()
    }

    private static func run(_ terminal: inout Terminal) async throws {
        typealias Part = (part: Snake, position: Terminal.Position)

        var isPaused = false
        var direction: Direction = .right
        var history: [Terminal.Position] = []
        var snake: [Part] = [
            (
                part: .head,
                position: (
                    x: terminal.size.width / 2,
                    y: terminal.size.height / 2
                )
            ),
            (
                part: .body,
                position: (
                    x: (terminal.size.width / 2) - 1,
                    y: terminal.size.height / 2
                )
            ),
        ]

        outer: while !Task.isCancelled {

            while isPaused {
                if Task.isCancelled { break outer }

                if let key = try terminal.getInput() {
                    switch key {
                    case .esc: isPaused.toggle()
                    default: continue
                    }
                }
            }

            clearSnake(&history)
            moveHead(&history)
            moveBody(&history)

            if let key = try terminal.getInput() {
                switch key {
                case .esc: isPaused.toggle()
                case .w where direction != .down: direction = .up
                case .a where direction != .right: direction = .left
                case .s where direction != .up: direction = .down
                case .d where direction != .left: direction = .right
                default: break
                }
            }

            try await Task.sleep(for: .milliseconds(250))
        }

        func clearSnake(_ history: inout [Terminal.Position]) {
            for idx in snake.indices {
                terminal.remove(at: snake[idx].position)
            }
        }

        func moveHead(_ history: inout [Terminal.Position]) {
            for idx in snake.indices where snake[idx].part == .head {
                switch direction {
                case .right:
                    snake[idx].position.x =
                        (snake[idx].position.x + 1) % terminal.size.width
                case .left:
                    snake[idx].position.x =
                        snake[idx].position.x > 0
                        ? snake[idx].position.x - 1
                        : terminal.size.width - 1
                case .up:
                    snake[idx].position.y =
                        snake[idx].position.y > 0
                        ? snake[idx].position.y - 1
                        : terminal.size.height - 1
                case .down:
                    snake[idx].position.y =
                        (snake[idx].position.y + 1) % terminal.size.height
                }

                history.append(snake[idx].position)
                if history.count > snake.count {
                    _ = history.removeFirst()
                }

                terminal.insert(
                    snake[idx].part.rawValue, at: snake[idx].position)
            }
        }

        func moveBody(_ history: inout [Terminal.Position]) {
            for idx in snake.indices where snake[idx].part == .body {
                snake[idx].position = history[idx-1]

                terminal.insert(
                    snake[idx].part.rawValue, at: snake[idx].position)
            }
        }
    }
}
