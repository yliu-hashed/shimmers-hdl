//
//  Shimmers/Scope/Assertion Type Message.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

enum ProofType {
    case assert
    case assume
    case never
}

extension AssertionType {
    func message(of proof: ProofType, for customMessage: String?) -> String {
        var message: String

        switch proof {
        case .assert:
            message = "Assertion failed"
        case .assume:
            message = "Assumption is contradicted"
        case .never:
            message = "Never is reachable"
        }

        if let customMessage {
            message += ": \(customMessage)"
        } else {
            switch self {
            case .bound:
                message += ": Index out of bound."
            case .overflowConvert:
                message += ": Integer cannot be represented."
            case .overflowMath:
                message += ": Integer overflow in math operation."
            case .assert:
                if proof == .assert {
                    message += "."
                    break
                }
                message += ": User assertion failed."
            case .assumption:
                if proof == .assume {
                    message += "."
                    break
                }
                return ": Assumption violated."
            case .never:
                if proof == .never {
                    message += "."
                    break
                }
                return "Never is reachable."
            case .custom(let name):
                return "Custom type '\(name)' failed."
            }
        }
        return message
    }
}
