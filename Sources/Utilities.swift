//
//  Utilities.swift
//  Snake
//
//  Created by Evren Sen on 2024-11-19.
//

typealias Size = (height: Int, width: Int)
typealias Position = (x: Int, y: Int)

enum Direction {
    case up
    case left
    case down
    case right
}

enum Key: Character {
    case esc = "\u{1B}"
    case w = "\u{77}"
    case a = "\u{61}"
    case s = "\u{73}"
    case d = "\u{64}"
}

enum Block: Character {
    case full = "█"
    case upper = "▀"
    case lower = "▄"
}

enum ANSIEscapeSequence {
    case enterScreen
    case leaveScreen
    case clearScreen
    case hideCursor
    case showCursor
    case moveCursor(x: Int, y: Int)

    var rawValue: String {
        switch self {
        case .enterScreen: return "\u{001B}[?1049h"
        case .leaveScreen: return "\u{001B}[?1049l"
        case .clearScreen: return "\u{001B}[2J"
        case .hideCursor: return "\u{001B}[?25l"
        case .showCursor: return "\u{001B}[?25h"
        case .moveCursor(let x, let y): return "\u{001B}[\(y+1);\(x+1)H"
        }
    }
}
