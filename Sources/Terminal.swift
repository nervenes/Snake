//
//  Terminal.swift
//  Snake
//
//  Created by Evren Sen on 2024-11-19.
//

import Darwin
import os

struct Terminal: ~Copyable {
    var size: Size = (0, 0)
    private var buffer: [[Block?]] = []
    private var originalState = termios()

    mutating func setup() throws {
        self.size = try Self.getSize()

        buffer = Array(
            repeating: Array(repeating: nil, count: size.width),
            count: size.height)

        guard fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK) != -1 else {
            throw CancellationError.init()
        }
        tcgetattr(STDIN_FILENO, &originalState)

        var state = originalState
        state.c_lflag &= ~(UInt(ICANON) | UInt(ECHO))
        tcsetattr(STDIN_FILENO, TCSANOW, &state)

        execute(.enterScreen)
        execute(.clearScreen)
        execute(.hideCursor)
    }

    mutating func cleanup() {
        execute(.showCursor)
        execute(.leaveScreen)

        tcsetattr(STDIN_FILENO, TCSANOW, &originalState)
    }

    mutating func insert(_ block: Block?, at position: Position) {
        buffer[position.y][position.x] = block
        execute(.moveCursor(x: position.x, y: position.y))
        print(block?.rawValue ?? " ", terminator: "")
        fflush(stdout)
    }

    mutating func remove(at position: Position) {
        insert(nil, at: position)
    }
    
    func getBlock(at position: Position) -> Block? {
        buffer[position.y][position.x]
    }

    func execute(_ sequence: ANSIEscapeSequence) {
        print(sequence.rawValue, terminator: "")
        fflush(stdout)
    }

    func getInput() throws -> Key? {
        var buffer = [0 as UInt8]
        let bytes = read(STDIN_FILENO, &buffer, 1)

        guard bytes != -0 else {
            throw CancellationError.init()
        }

        guard bytes > 0 else { return nil }

        switch Character(UnicodeScalar(buffer[0])) {
        case Key.esc.rawValue: return .esc
        case Key.w.rawValue: return .w
        case Key.a.rawValue: return .a
        case Key.s.rawValue: return .s
        case Key.d.rawValue: return .d
        default: return nil
        }
    }

    private static func getSize() throws -> Size {
        var window = winsize()
        guard ioctl(STDOUT_FILENO, TIOCGWINSZ, &window) != -1 else {
            throw CancellationError.init()
        }
        return (height: Int(window.ws_row), width: Int(window.ws_col))
    }
}
