//
//  ShimmersMacros/Convert Wire Struct/Wire Struct Member Survey.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

internal struct WireStructMemberRep {
    var name: TokenSyntax
    var valueType: TypeSyntax
    var synthType: TypeSyntax
    var defaultValue: InitializerClauseSyntax?
}

func extractDataMembers(
    for decl: VariableDeclSyntax,
    into members: inout [WireStructMemberRep],
    in context: some MacroExpansionContext
) {
    guard !containsSimOnly(attributes: decl.attributes) else { return }

    guard (decl.bindingSpecifier.tokenKind == .keyword(.let) ||
           decl.bindingSpecifier.tokenKind == .keyword(.var)) else {
        let err = MacroExpansionErrorMessage("Unknown specifier '\(decl.bindingSpecifier.trimmed)'")
        context.addDiagnostics(from: err, node: decl.bindingSpecifier)
        return
    }

    for binding in decl.bindings {
        guard binding.accessorBlock == nil else { continue }
        guard let type = binding.typeAnnotation?.type else {
            let err = MacroExpansionErrorMessage("Member variable must have type annotation")
            context.addDiagnostics(from: err, node: binding.pattern)
            continue
        }

        guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
            let err = MacroExpansionErrorMessage("Member vadiable must use an identifier pattern")
            context.addDiagnostics(from: err, node: binding.pattern)
            continue
        }

        let refType = convert(type: type, in: context)

        members.append(WireStructMemberRep(
            name: "\(identifier.identifier.trimmed)",
            valueType: type,
            synthType: refType.trimmed,
            defaultValue: binding.initializer
        ))
    }
}
