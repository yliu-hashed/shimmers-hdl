//
//  Shimmers/Mangle/File Name Mangle.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

/// Create the file name for a given module
func buildFileName(for moduleName: String) -> String {
    let mangled = mangleFile(name: moduleName)
    if mangled.lengthOfBytes(using: .utf8) < 64 {
        return mangled
    }
    let suffix = mangled.prefix(32)
    return "\(suffix)_\(moduleName.djb2HashValue)"
}

private func mangleFile(name: String) -> String {
    var str = ""
    var wasLetter = true
    for char in name {
        guard !char.isWhitespace else { continue }
        if char.isLetter || char.isNumber {
            if !wasLetter { str += "_" }
            str += "\(char)"
            wasLetter = true
            continue
        }
        if !str.isEmpty { str += "_" }
        switch char {
        case "_":
            str += "us"
        case "+":
            str += "pl"
        case "-":
            str += "ds"
        case "*":
            str += "st"
        case "/":
            str += "sl"
        case "%":
            str += "pc"
        case "^":
            str += "cr"
        case "&":
            str += "ap"
        case "|":
            str += "br"
        case "<":
            str += "la"
        case ">":
            str += "ra"
        case "=":
            str += "eq"
        case "!":
            str += "ex"
        case "~":
            str += "tl"
        case ".":
            str += "dt"
        case ",":
            str += "cm"
        case ":":
            str += "cl"
        case "\\":
            str += "bs"
        case "[":
            str += "lb"
        case "]":
            str += "rb"
        case "\"":
            str += "qt"
        case "'":
            str += "ap"
        case "(":
            str += "lp"
        case ")":
            str += "rp"
        default:
            fatalError("Unsupported symbol for mangling: \(char)")
        }
        wasLetter = false
    }
    return str
}
