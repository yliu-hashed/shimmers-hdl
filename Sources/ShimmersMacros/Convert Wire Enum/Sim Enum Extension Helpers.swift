//
//  ShimmersMacros/Convert Wire Enum/Sim Enum Extension Helpers.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildWireBitLength(
    for caseReps: [WireEnumCaseRep],
    contentBitWidthName: TokenSyntax?,
    in context: some MacroExpansionContext
) -> DeclSyntax {
    let kindBitWidth = clog2(caseReps.count)
    let expr: ExprSyntax = if let contentBitWidthName = contentBitWidthName {
        "\(contentBitWidthName) + \(raw: kindBitWidth)"
    } else {
        "\(raw: kindBitWidth)"
    }
    return "@inlinable static var bitWidth: Int {\(expr)}"
}

func buildWireContentBitLength(
    for caseReps: [WireEnumCaseRep],
    contentBitWidthName: TokenSyntax,
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    items.append(.decl("var _width: Int = 0"))
    items.append(.expr("_width = _width + 0"))
    for caseRep in caseReps where !caseRep.members.isEmpty {
        let sum = caseRep.members
            .map { "(\($0.valueType)).bitWidth" }
            .joined(separator: " + ")
        items.append(.expr("_width = max(_width, \(raw: sum))"))
    }
    items.append(.expr("return _width"))
    return "@inlinable static var \(contentBitWidthName): Int {\(items.buildList())}"
}

func buildWireBitTraverser(
    for caseReps: [WireEnumCaseRep],
    contentBitWidthName: TokenSyntax?,
    in context: some MacroExpansionContext
) -> DeclSyntax {
    let kindBitWidth = clog2(caseReps.count)

    var items: [CodeBlockItemSyntax.Item] = []
    if let contentBitWidthName = contentBitWidthName {
        items.append(.decl("let contentBitWidth = Self.\(contentBitWidthName)"))
    }

    var switchCases: [SwitchCaseSyntax] = []

    for (index, caseRep) in caseReps.enumerated() {
        var items: [CodeBlockItemSyntax.Item] = []
        items.append(.decl("let kind: UIntN<\(raw: kindBitWidth)> = \(raw: index)"))
        items.append(.expr("kind._traverse(using: &traverser)"))

        if contentBitWidthName != nil {
            var parameters: [LabeledExprSyntax] = []
            for index in caseRep.members.indices {
                parameters.append(LabeledExprSyntax(expression: ExprSyntax("$a\(raw: index)")))
            }
            parameters.append(LabeledExprSyntax(label: "length", expression: ExprSyntax("contentBitWidth")))
            items.append(.decl("let content = _enum_pack(\(parameters.buildList()))"))

            items.append(.expr("traverser.visit(content)"))
        }

        if caseRep.members.isEmpty {
            let switchCase: SwitchCaseSyntax = "case .\(caseRep.name):\(items.buildList())"
            switchCases.append(switchCase)
        } else {
            let list = LabeledExprListSyntax {
                for index in caseRep.members.indices {
                    LabeledExprSyntax(expression: ExprSyntax("let $a\(raw: index)"))
                }
            }
            let switchCase: SwitchCaseSyntax = "case .\(caseRep.name)(\(list)):\(items.buildList())"
            switchCases.append(switchCase)
        }
    }

    items.append(.stmt("switch self {\(switchCases.buildList())}"))

    return "func _traverse(using traverser: inout some _BitTraverser) {\(items.buildList())}"
}

func buildWireBitInit(
    for caseReps: [WireEnumCaseRep],
    contentBitWidthName: TokenSyntax?,
    in context: some MacroExpansionContext
) -> DeclSyntax {
    let kindBitWidth = clog2(caseReps.count)

    var items: [CodeBlockItemSyntax.Item] = []
    if let contentBitWidthName = contentBitWidthName {
        items.append(.decl("let contentBitWidth = Self.\(contentBitWidthName)"))
    }

    items.append(.decl("let kind: UIntN<\(raw: kindBitWidth)> = .init(byPoppingBits: &builder)"))

    var switchCases: [SwitchCaseSyntax] = []
    for (index, caseRep) in caseReps.enumerated() {
        var items: [CodeBlockItemSyntax.Item] = []

        if caseRep.members.isEmpty {
            if contentBitWidthName != nil {
                items.append(.expr("_ = builder.pop(count: contentBitWidth)"))
            }
            items.append(.stmt("self = .\(caseRep.name)"))
        } else {
            var parameters: [LabeledExprSyntax] = []
            for member in caseRep.members {
                parameters.append(LabeledExprSyntax(expression: ExprSyntax("(\(member.valueType)).self")))
            }
            parameters.append(LabeledExprSyntax(label: "from", expression: ExprSyntax("&builder")))
            parameters.append(LabeledExprSyntax(label: "length", expression: ExprSyntax("contentBitWidth")))
            items.append(.decl("let items = _enum_unpack(\(parameters.buildList()))"))

            if caseRep.members.count == 1 {
                items.append(.expr("self = .\(caseRep.name)(items)"))
            } else {
                var returnParameters: [LabeledExprSyntax] = []
                for (index, member) in caseRep.members.enumerated() {
                    let label = member.firstName?.identifier?.name
                    returnParameters.append(LabeledExprSyntax(label: label, expression: ExprSyntax("items.\(raw: index)")))
                }

                items.append(.expr("self = .\(caseRep.name)(\(returnParameters.buildList()))"))
            }
        }

        let switchCase: SwitchCaseSyntax = "case \(raw: index):\(items.buildList())"
        switchCases.append(switchCase)
    }

    switchCases.append("default: fatalError(\"unexpected value\")")

    items.append(.stmt("switch kind {\(switchCases.buildList())}"))

    return "init(byPoppingBits builder: inout some _BitPopper) {\(items.buildList())}"
}
