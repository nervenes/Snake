//
//  Snake.swift
//  Snake
//
//  Created by Evren Sen on 2024-11-19.
//

import Dispatch

@main
struct Snake: ~Copyable {
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

        var position: Position = (x: 0, y: 0)

        var block: Block = .upper
        var direction: Direction = .right
        var previousDirection: Direction = direction

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

            switch (direction, block) {
            case (.right, _):
                position.x = (position.x + 1) % terminal.size.width
            case (.left, _):
                position.x =
                    position.x > 0 ? position.x - 1 : terminal.size.width - 1
            case (.up, .upper), (.up, .full):
                position.y =
                    position.y > 0 ? position.y - 1 : terminal.size.height - 1
            case (.down, .lower), (.down, .full):
                position.y = (position.y + 1) % terminal.size.height
            default: break
            }

            switch (direction, block) {
            case (.right, .full), (.left, .full):
                if let toReplace = terminal.getBlock(at: position) {
                    switch toReplace {
                    case .upper, .lower: block = .full
                    default: break
                    }
                } else {
                    switch previousDirection {
                    case .down: block = .lower
                    case .up: block = .upper
                    default: break
                    }
                }
            case (.right, _), (.left, _):
                if let toReplace = terminal.getBlock(at: position) {
                    switch toReplace {
                    case .upper, .lower: block = .full
                    default: break
                    }
                }
            case (.up, .full):
                block = .lower
            case (.up, .upper):
                block = .lower
            case (.up, .lower):
                block = .full
            case (.down, .full):
                block = .upper
            case (.down, .upper):
                block = .full
            case (.down, .lower):
                block = .upper
            }

            terminal.insert(block, at: position)
            previousDirection = direction

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

            try await Task.sleep(for: .milliseconds(175))
        }
    }
}
