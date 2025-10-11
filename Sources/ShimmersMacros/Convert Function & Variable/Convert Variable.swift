//
//  ShimmersMacros/Convert Function & Variable/Convert Variable.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics


func buildVariable(
    for decl: VariableDeclSyntax,
    noStorage: Bool = false,
    in context: some MacroExpansionContext
) throws -> [VariableDeclSyntax] {

    guard !containsSimOnly(attributes: decl.attributes) else { return [] }

    guard (decl.bindingSpecifier.tokenKind == .keyword(.let) ||
           decl.bindingSpecifier.tokenKind == .keyword(.var)) else {
        let err = MacroExpansionErrorMessage("Unsupported accessor")
        context.addDiagnostics(from: err, node: decl.bindingSpecifier)
        return []
    }

    var variables: [VariableDeclSyntax] = []
    for binding in decl.bindings {
        guard let m = try buildMember(for: binding, from: decl, noStorage: noStorage, in: context) else { continue }
        variables.append(m)
    }
    return variables
}

private func buildMember(
    for binding: PatternBindingSyntax,
    from decl: VariableDeclSyntax,
    noStorage: Bool,
    in context: some MacroExpansionContext
) throws -> VariableDeclSyntax? {

    guard let type = binding.typeAnnotation?.type else {
        let err = MacroExpansionErrorMessage("Must have type annotation")
        context.addDiagnostics(from: err, node: binding.pattern)
        return nil
    }

    guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
        let err = MacroExpansionErrorMessage("Must be an identifier")
        context.addDiagnostics(from: err, node: binding.pattern)
        return nil
    }

    let refType = convert(type: type, in: context)

    if let block = binding.accessorBlock {
        // accessor like function
        guard let codeList = block.accessors.as(CodeBlockItemListSyntax.self) else {
            let err = MacroExpansionErrorMessage("Complex Accessors are not yet supported")
            context.addDiagnostics(from: err, node: block.accessors)
            return nil
        }

        let loc = CodeListDebugInfo(
            name: "accessor",
            entry: context.location(of: block.leftBrace)
        )

        let newCodeBlock = try convertFullCodeList(
            for: codeList,
            returnRefType: refType,
            isMutating: false,
            at: loc,
            in: context
        )

        let newBinding = PatternBindingSyntax(
            pattern: identifier,
            typeAnnotation: TypeAnnotationSyntax(type: refType),
            accessorBlock: AccessorBlockSyntax(
                accessors: AccessorBlockSyntax.Accessors(newCodeBlock)
            )
        )

        return VariableDeclSyntax(
            modifiers: decl.modifiers,
            bindingSpecifier: decl.bindingSpecifier,
            bindings: [ newBinding ]
        ).trimmed
    } else {
        for modifier in decl.modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.static):
                let err = MacroExpansionErrorMessage("Shimmers does not support stored static mutable variables")
                context.addDiagnostics(from: err, node: decl.bindingSpecifier)
                return nil
            default:
                break
            }
        }

        // data member
        if noStorage { return nil }

        let newBinding = PatternBindingSyntax(
            pattern: identifier,
            typeAnnotation: TypeAnnotationSyntax(type: refType)
        )

        return VariableDeclSyntax(
            attributes: "@_Member",
            modifiers: decl.modifiers.trimmed,
            bindingSpecifier: decl.bindingSpecifier,
            bindings: [ newBinding ]
        ).trimmed
    }
}
