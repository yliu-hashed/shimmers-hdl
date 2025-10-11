//
//  ShimmersCLIWrapper/Assertion Type.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Shimmers
import ArgumentParser

struct AssertionDisableSetPortion: ExpressibleByArgument {
    var portion: AssertionSetPortion
    var include: Bool

    static var all: AssertionDisableSetPortion {
        AssertionDisableSetPortion(.all)
    }

    init (_ portion: AssertionSetPortion) {
        self.portion = portion
        include = true
    }

    init?(argument: String) {
        if let portion = AssertionSetPortion(argument: argument) {
            self.portion = portion
            include = true
            return
        }

        if argument.first == "x" {
            let rest = argument.dropFirst()
            if let portion = AssertionSetPortion(argument: String(rest)) {
                self.portion = portion
                include = false
                return
            }
        }

        return nil
    }

    static var allValueStrings: [String] {
        let basicNames = (AssertionType.builtinValues.map(\.name) + ["overflow", "all"]).sorted()
        let negatedNames = basicNames + basicNames.map({"x\($0)"})
        return negatedNames
    }

    var defaultValueDescription: String {
        if include {
            return portion.defaultValueDescription
        } else {
            return "x\(portion.defaultValueDescription)"
        }
    }
}


enum AssertionSetPortion {
    case single(type: AssertionType)
    case overflow
    case all

    var assertions: AssertionSet {
        switch self {
        case .single(let type):
            return [type]
        case .overflow:
            return [.overflowMath, .overflowConvert]
        case .all:
            return .all
        }
    }
    
    init?(argument: String) {
        switch argument {
        case "overflow":
            self = .overflow
        case "all":
            self = .all
        default:
            let single = AssertionType(name: argument)
            self = .single(type: single)
        }
    }

    var defaultValueDescription: String {
        switch self {
        case .single(let type):
            return type.name
        case .overflow:
            return "overflow"
        case .all:
            return "all"
        }
    }
}
