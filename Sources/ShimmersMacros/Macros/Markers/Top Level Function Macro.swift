//
//  ShimmersMacros/Macros/Markers/Top Level Function Macro.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

// This marker macro that does nothing but to check it is in the right place
struct TopLevelFunctionMacro: PeerMacro {

    private static func checkFuncAttachment(
        decl: some DeclSyntaxProtocol
    ) -> Bool {
        guard decl.is(FunctionDeclSyntax.self) else { return false }
        return true
    }

    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let decl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("'@TopLevel' can only be applied to functions.")
        }

        guard checkHardwareParent(attributes: decl.attributes, in: context) else {
            throw MacroExpansionErrorMessage("'@TopLevel' macro must be placed inside a '@HardwareWire' struct.")
        }

        guard checkFuncAttachment(decl: declaration) else {
            throw MacroExpansionErrorMessage("'@TopLevel' macro must be attached to a function.")
        }

        return []
    }
}
