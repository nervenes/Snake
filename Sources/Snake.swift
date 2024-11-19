//
//  Snake.swift
//  Snake
//
//  Created by Evren Sen on 2024-11-19.
//

import Dispatch

@main
struct Snake {
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
        var isPaused = false
        var position = (x: 0, y: 0)
        var previousPosition = (x: 0, y: 0)
        var block: Block = .upper
        var direction: Direction = .right
        var oppositeDirection: Direction {
            switch direction {
            case .right: return .left
            case .left: return .right
            case .up: return .down
            case .down: return .up
            }
        }

        while !Task.isCancelled {
            while isPaused {
                if let key = try terminal.getInput() {
                    switch key {
                    case .esc: isPaused.toggle()
                    default: continue
                    }
                }
            }
            
            previousPosition = position

            switch (direction, block) {
            case (.right, _):
                position.x = (position.x + 1) % terminal.size.width
            case (.left, _):
                position.x =
                    position.x > 0 ? position.x - 1 : terminal.size.width - 1
            case (.up, .upper):
                block = .lower
                position.y =
                    position.y > 0 ? position.y - 1 : terminal.size.height - 1
            case (.up, .lower):
                block = .upper
            case (.down, .lower):
                block = .upper
                position.y = (position.y + 1) % terminal.size.height
            case (.down, .upper):
                block = .lower
            }

            terminal.remove(at: previousPosition)
            terminal.insert(block, at: position)

            if let key = try terminal.getInput() {
                switch key {
                case .esc: isPaused.toggle()
                case .w: direction = .up
                case .a: direction = .left
                case .s: direction = .down
                case .d: direction = .right
                }
            }

            try await Task.sleep(for: .milliseconds(150))
        }
    }
}
