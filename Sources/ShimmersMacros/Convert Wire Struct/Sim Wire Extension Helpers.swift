//
//  ShimmersMacros/Convert Wire Struct/Sim Wire Extension Helpers.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildWireBitLength(
    for members: [WireStructMemberRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {
    guard let first = members.first else {
        return "@inlinable static var bitWidth: Int { 0 }"
    }
    var expr: ExprSyntax = "(\(first.valueType)).bitWidth"
    for member in members.dropFirst() {
        expr = "\(expr) + (\(member.valueType)).bitWidth"
    }
    return "@inlinable static var bitWidth: Int {\(expr)}"
}

func buildWireBitTraverser(
    for members: [WireStructMemberRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var expr: [CodeBlockItemSyntax.Item] = []
    for member in members {
        expr.append(.stmt("if !traverser.skip(width: (\(member.valueType)).bitWidth) {\(member.name)._traverse(using: &traverser)}"))
    }
    return "func _traverse(using traverser: inout some _BitTraverser) {\(expr.buildList())}"
}

func buildWireBitInit(
    for members: [WireStructMemberRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var expr: [CodeBlockItemSyntax.Item] = []
    for member in members {
        expr.append(.expr("self.\(member.name) = .init(_byPoppingBits: &builder)"))
    }
    return "init(_byPoppingBits builder: inout some _BitPopper) {\(expr.buildList())}"
}
