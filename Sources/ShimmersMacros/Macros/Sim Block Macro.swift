//
//  ShimmersMacros/Macros/Sim Block Macro.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct SimBlockMacro: ExpressionMacro {
    static func decodeParam(
        of node: borrowing some FreestandingMacroExpansionSyntax,
        in context: borrowing some MacroExpansionContext
    ) throws -> ClosureExprSyntax {

        let block: ClosureExprSyntax

        if let arg = node.arguments.last {
            guard let closure = arg.expression.as(ClosureExprSyntax.self) else {
                throw MacroExpansionErrorMessage("Block parameter must be a closure")
            }
            block = closure
        } else {
            guard let closure = node.trailingClosure else {
                throw MacroExpansionErrorMessage("Block parameter must be a closure")
            }
            block = closure
        }

        return block
    }

    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {

        if !checkHardwareParent(attributes: nil, in: context) {
            let warning = MacroExpansionWarningMessage("'#sim {...}' will always execute outside of a '@HardwareWire' struct")
            let diag = Diagnostic(node: node, message: warning)
            context.diagnose(diag)
        }

        let closure = try decodeParam(of: node, in: context).trimmed

        return "\(closure)()"
    }
}

