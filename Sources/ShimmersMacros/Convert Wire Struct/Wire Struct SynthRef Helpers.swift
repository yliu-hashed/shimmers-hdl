//
//  ShimmersMacros/Convert Wire Struct/Wire Struct SynthRef Helpers.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildRefBitLength(
    for members: [WireStructMemberRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var expr: ExprSyntax = "(\(members.first!.synthType))._bitWidth"
    for member in members.dropFirst() {
        expr = "\(expr) + (\(member.synthType))._bitWidth"
    }
    return "@inlinable static var _bitWidth: Int {\(expr)}"
}

func buildRefWireTraverser(
    for members: [WireStructMemberRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    for member in members {
        items.append(.stmt("if !traverser.skip(width: (\(member.synthType))._bitWidth) {\(member.name)._traverse(using: &traverser)}"))
    }
    return "func _traverse(using traverser: inout some _WireTraverser) {\(items.buildList())}"
}

func buildRefBitInit(
    for members: [WireStructMemberRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    for member in members {
        items.append(.expr("self.\(member.name) = .init(byPoppingBits: &builder)"))
    }
    return "init(byPoppingBits builder: inout some _WirePopper) {\(items.buildList())}"
}

func buildRefPortInit(
    for members: [WireStructMemberRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    for member in members {
        let name: ExprSyntax = "_joinModuleName(base: parentName, suffix: \"\(member.name)\")"
        items.append(.expr("self.\(member.name) = .init(parentName: \(name), body: body)"))
    }
    return "init(parentName: String?, body: (String, Int) -> [_WireID]) {\(items.buildList())}"
}

func buildRefPortApplication(
    for members: [WireStructMemberRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    for member in members {
        let name: ExprSyntax = "_joinModuleName(base: parentName, suffix: \"\(member.name)\")"
        items.append(.expr("self.\(member.name)._applyPerPart(parentName: \(name), body: body)"))
    }
    return "func _applyPerPart(parentName: String?, body: (String, [_WireID]) -> Void) {\(items.buildList())}"
}

func buildVirtualizer(
    for members: [WireStructMemberRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    for member in members.lazy {
        items.append(.expr("_\(raw: member.name.text).virtualize()"))
    }
    return "mutating func _virtualize() {\(items.buildList())}"
}

func buildDevirtualizer(
    for members: [WireStructMemberRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    for member in members.lazy {
        items.append(.expr("_\(raw: member.name.text).devirtualize()"))
    }
    return "mutating func _devirtualize() {\(items.buildList())}"
}

func buildMemberWiseInit(
    for members: [WireStructMemberRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {
    // build list

    let list = FunctionParameterListSyntax {
        for member in members {
            let clause: InitializerClauseSyntax? = if let value = member.defaultValue?.value {
                InitializerClauseSyntax(value: convertExpression(value, in: context))
            } else {
                nil
            }
            FunctionParameterSyntax(
                firstName: member.name,
                type: member.synthType,
                defaultValue: clause
            )
        }
    }

    let clause = FunctionParameterClauseSyntax(parameters: list)
    let signature = FunctionSignatureSyntax(parameterClause: clause)

    // build body
    var items: [CodeBlockItemSyntax.Item] = []
    for member in members {
        items.append(.expr("self.\(member.name) = \(member.name)"))
    }
    let block: CodeBlockSyntax = "{\(items.buildList())}"

    let decl = InitializerDeclSyntax(signature: signature, body: block)
    return DeclSyntax(decl)
}
