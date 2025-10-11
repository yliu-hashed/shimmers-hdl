//
//  ShimmersMacros/Macros/Formals/Never Macro.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct NeverMacro: ExpressionMacro {
    static func simpleDecodeParam(
        of node: borrowing MacroExpansionExprSyntax
    ) -> (type: ExprSyntax, message: ExprSyntax?)? {

        var type: ExprSyntax = ".never"
        var message: ExprSyntax? = nil

        var arguments = node.arguments.reversed().map { $0 }

        if let arg = arguments.last, arg.label?.text == "type" {
            type = arg.expression
            arguments.removeLast()
        }

        if let arg = arguments.last, arg.label == nil {
            message = arg.expression
            arguments.removeLast()
        }

        guard arguments.isEmpty else { return nil }

        return (type, message)
    }

    static func decodeParam(
        of node: borrowing some FreestandingMacroExpansionSyntax,
        in context: borrowing some MacroExpansionContext
    ) throws -> (type: ExprSyntax, message: ExprSyntax?) {

        var type: ExprSyntax = ".never"
        var message: ExprSyntax? = nil

        var arguments = node.arguments.reversed().map { $0 }

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

        return (type, message)
    }

    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {

        if !checkHardwareParent(in: context) {
            let warning = MacroExpansionWarningMessage("'#never' can be replaced by regular assert outside of '@HardwareWire' struct")
            let diag = Diagnostic(node: node, message: warning)
            context.diagnose(diag)
        }

        let (type, message) = try decodeParam(of: node, in: context)

        return "Swift.fatalError(\(message ?? "\"Simulation assertion failed.\"")) // \(type.trimmed)"
    }
}
