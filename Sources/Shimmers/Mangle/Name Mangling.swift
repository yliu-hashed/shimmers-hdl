//
//  Shimmers/Mangle/Name Mangling.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

internal func verilogMangle(name: String) -> String {
    var str = ""
    for char in name {
        guard !char.isWhitespace else { continue }
        if char.isLetter || char.isNumber {
            str += "\(char)"
            continue
        }
        switch char {
        case " ":
            str += "$space$"
        case "\t":
            str += "$tab$"
        case "\n":
            str += "$newline$"
        case "\\":
            str += "$backslash$"
        default:
            str += "\(char)"
        }
    }
    return str
}
