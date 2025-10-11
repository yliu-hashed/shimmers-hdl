//
//  ShimmersMacros/Convert Code Block/Add Variable Decl.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics


func addVarDecl(
    referencing decl: VariableDeclSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    in context: some MacroExpansionContext
) throws {
    let specifier = decl.bindingSpecifier

    // Add a `let` declaration only if there are initializers
    if specifier.tokenKind == .keyword(.let), decl.bindings.allSatisfy({ $0.initializer != nil }) {
        try addLetDecl(for: decl, into: &items, in: context)
        return
    }

    guard specifier.tokenKind == .keyword(.let) || specifier.tokenKind == .keyword(.var) else {
        let err = MacroExpansionErrorMessage("Shimmers does not yet support binding specifier '\(specifier.text)'")
        context.addDiagnostics(from: err, node: specifier)
        return
    }

    for binding in decl.bindings {
        // make sure not have any accessor
        if let accessor = binding.accessorBlock {
            let err = MacroExpansionErrorMessage("Accessor are not yet supported in synthesizable portions")
            context.addDiagnostics(from: err, node: accessor)
            continue
        }

        let newTypeAnnot: TypeAnnotationSyntax?
        if let type = binding.typeAnnotation?.type {
            let type = convert(type: type, in: context)
            newTypeAnnot = TypeAnnotationSyntax(type: type)
        } else {
            newTypeAnnot = nil
        }

        let newInitializer: InitializerClauseSyntax?
        if let initializer = binding.initializer {
            let expr = convertExpression(initializer.value, in: context)
            newInitializer = InitializerClauseSyntax(value: expr)
        } else {
            newInitializer = nil
        }

        let newBinding = PatternBindingSyntax(
            pattern: binding.pattern,
            typeAnnotation: newTypeAnnot,
            initializer: newInitializer
        )

        // create new item
        items.append(.decl("@_Local var \(newBinding)"))
    }
}

private func addLetDecl(
    for decl: VariableDeclSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    in context: some MacroExpansionContext
) throws {
    assert(decl.bindingSpecifier.tokenKind == .keyword(.let))

    for binding in decl.bindings {
        // make sure not have any accessor
        if let accessor = binding.accessorBlock {
            let err = MacroExpansionErrorMessage("Accessor are not yet supported in synthesizable portions")
            context.addDiagnostics(from: err, node: accessor)
            continue
        }

        let newTypeAnnot: TypeAnnotationSyntax?
        if let type = binding.typeAnnotation?.type {
            let type = convert(type: type, in: context)
            newTypeAnnot = TypeAnnotationSyntax(type: type)
        } else {
            newTypeAnnot = nil
        }

        let newInitializer: InitializerClauseSyntax?
        if let initializer = binding.initializer {
            let expr = convertExpression(initializer.value, in: context)
            newInitializer = InitializerClauseSyntax(value: expr)
        } else {
            newInitializer = nil
        }

        let newBinding = PatternBindingSyntax(
            pattern: binding.pattern.trimmed,
            typeAnnotation: newTypeAnnot,
            initializer: newInitializer
        )

        // create new item
        items.append(.decl("let \(newBinding)"))
    }
}
