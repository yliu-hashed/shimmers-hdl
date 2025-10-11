//
//  ShimmersMacros/Macros/Formals/Assert Macro.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct AssertMacro: ExpressionMacro {
    static func simpleDecodeParam(
        of node: borrowing MacroExpansionExprSyntax
    ) -> (value: ExprSyntax, type: ExprSyntax, message: ExprSyntax?)? {

        var value: ExprSyntax? = nil
        var type: ExprSyntax = ".assert"
        var message: ExprSyntax? = nil

        var arguments = node.arguments.reversed().map { $0 }

        guard let arg1 = arguments.last, arg1.label == nil else { return nil }
        value = arg1.expression
        arguments.removeLast()

        if let arg = arguments.last, arg.label?.text == "type" {
            type = arg.expression
            arguments.removeLast()
        }

        if let arg = arguments.last, arg.label == nil {
            message = arg.expression
            arguments.removeLast()
        }

        guard arguments.isEmpty else { return nil }

        guard let value = value else { return nil }

        return (value, type, message)
    }

    static func decodeParam(
        of node: borrowing some FreestandingMacroExpansionSyntax,
        in context: borrowing some MacroExpansionContext
    ) throws -> (value: ExprSyntax, type: ExprSyntax, message: ExprSyntax?) {

        var value: ExprSyntax? = nil
        var type: ExprSyntax = ".assert"
        var message: ExprSyntax? = nil

        var arguments = node.arguments.reversed().map { $0 }

        guard let arg1 = arguments.last, arg1.label == nil else {
            throw MacroExpansionErrorMessage("Missing asserted value argument")
        }
        value = arg1.expression
        arguments.removeLast()

        if let arg = arguments.last, arg.label?.text == "type" {
            type = arg.expression
            arguments.removeLast()
        }

        if let arg = arguments.last, arg.label == nil {
            message = arg.expression
            arguments.removeLast()
        }

        if let arg = arguments.last {
            throw MacroExpansionErrorMessage("Extra extra argument \(arg)")
        }

        guard let value = value else {
            throw MacroExpansionErrorMessage("Incorrect argument")
        }

        return (value, type, message)
    }

    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {

        if !checkHardwareParent(in: context) {
            let warning = MacroExpansionWarningMessage("'#assert' can be replaced by regular assert outside of '@HardwareWire' struct")
            let diag = Diagnostic(node: node, message: warning)
            context.diagnose(diag)
        }

        let (value, type, message) = try decodeParam(of: node, in: context)

        return "Swift.precondition(\(value.trimmed), \(message ?? "\"Simulation assertion failed.\"")) // \(type.trimmed)"
    }
}
