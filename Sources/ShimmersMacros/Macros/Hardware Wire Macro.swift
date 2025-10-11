//
//  ShimmersMacros/Macros/Hardware Wire Macro.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct HardwareWireMacro: ExtensionMacro, PeerMacro {

    private static func decodeParameter(
        node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) throws -> Bool {
        var isFlatten: Bool = false

        // return default when no arguments are provided
        guard let args = node.arguments?.as(LabeledExprListSyntax.self) else {
            return isFlatten
        }

        var arguments = args.reversed().map { $0 }

        if let arg = arguments.last, arg.label?.text == "flatten" {
            arguments.removeLast()
            guard let expr = arg.expression.as(BooleanLiteralExprSyntax.self) else {
                throw MacroExpansionErrorMessage("Only support boolean literally 'true' or 'false'")
            }
            isFlatten = expr.literal.tokenKind == .keyword(.true)
        }

        return isFlatten
    }

    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let flatten = try decodeParameter(node: node, in: context)

        switch declaration.kind {
        case .structDecl:
            let structDecl = declaration.cast(StructDeclSyntax.self)
            let ref = try buildSynthRefStruct(
                for: structDecl,
                flatten: flatten,
                in: context
            )
            return [ DeclSyntax(ref) ]
        case .enumDecl:
            let enumDecl = declaration.cast(EnumDeclSyntax.self)
            let ref = try buildSynthRefEnum(
                for: enumDecl,
                flatten: flatten,
                in: context
            )
            return [ DeclSyntax(ref) ]
        default:
            throw MacroExpansionErrorMessage("'@HardwareWire' can only be applied to a global struct, enum, or function.")
        }
    }

    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // validate attached to a struct

        switch declaration.kind {
        case .structDecl:
            let decl = declaration.cast(StructDeclSyntax.self)
            let ext = try buildWireExtention(for: decl, in: context)
            return [ ext ]
        case .enumDecl:
            let decl = declaration.cast(EnumDeclSyntax.self)
            let ext = try buildWireExtention(for: decl, in: context)
            return [ ext ]
        default: break
        }

        return []
    }
}
