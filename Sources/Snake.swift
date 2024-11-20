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

enum Part: Character {
    case head = "@"
    case body = "o"
    case food = "*"
}

@main
struct Main {
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
        var isDead = false
        var isPaused = false
        var snake: [Part] = [.head, .body]
        var direction: Direction = .right
        var history: [Terminal.Position] = []
        var position: Terminal.Position = (
            x: terminal.size.width / 2,
            y: terminal.size.height / 2
        )
        
        for _ in 0..<max(1, min(20, Int(Double(terminal.size.width * terminal.size.height) / 500.0))) {
            if let position = terminal.getRandomEmptyPosition() {
                terminal.insert(Part.food.rawValue, at: position)
            }
        }

        outer: while !Task.isCancelled {
            while isPaused || isDead {
                if Task.isCancelled { break outer }

                if let key = try terminal.getInput(), isPaused == true {
                    switch key {
                    case .esc: isPaused.toggle()
                    default: continue
                    }
                }
            }

            switch direction {
            case .right:
                position.x =
                    (position.x + 1) % terminal.size.width
            case .left:
                position.x =
                    position.x > 0
                    ? position.x - 1
                    : terminal.size.width - 1
            case .up:
                position.y =
                    position.y > 0
                    ? position.y - 1
                    : terminal.size.height - 1
            case .down:
                position.y =
                    (position.y + 1) % terminal.size.height
            }
            
            if terminal.check(is: Part.body.rawValue, at: position) {
                isDead = true
                continue
            }
            
            if terminal.check(is: Part.food.rawValue, at: position) {
                snake.append(.body)
                
                if let position = terminal.getRandomEmptyPosition() {
                    terminal.insert(Part.food.rawValue, at: position)
                }
            }
            
            terminal.remove(at: position)
            for position in history {
                terminal.remove(at: position)
            }

            history.append(position)
            if history.count > snake.count {
                _ = history.removeFirst()
            }

            terminal.insert(Part.head.rawValue, at: position)
            
            for idx in snake.indices where snake[idx] == .body {
                let position = history[idx - 1]
                terminal.insert(Part.body.rawValue, at: position)
            }

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

            try await Task.sleep(for: .milliseconds(150))
        }
    }
}
