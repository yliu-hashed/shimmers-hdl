//
//  ShimmersMacros/Macros/Hardware Function Macro.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct HardwareFunctionMacro: PeerMacro {

    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let decl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("'@HardwareFunction' can only be applied to functions.")
        }

        return try buildGenFunc(for: decl, isGlobal: true, in: context)
    }
}
