//
//  ShimmersMacros/Convert Wire Enum/Wire Enum SynthRef Helpers.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildRefBitLength(
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
    return "@inlinable static var _bitWidth: Int {\(expr)}"
}

func buildRefContentBitLength(
    for caseReps: [WireEnumCaseRep],
    contentBitWidthName: TokenSyntax,
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    items.append(.decl("var _width: Int = 0"))
    items.append(.expr("_width = _width + 0"))
    for caseRep in caseReps where !caseRep.members.isEmpty {
        let sum = caseRep.members
            .map { "(\($0.synthType))._bitWidth" }
            .joined(separator: " + ")
        items.append(.expr("_width = max(_width, \(raw: sum))"))
    }
    items.append(.expr("return _width"))
    return "@inlinable static var \(contentBitWidthName): Int {\(items.buildList())}"
}

func buildRefWireTraverser(
    for caseReps: [WireEnumCaseRep],
    contentBitWidthName: TokenSyntax?,
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    let kindBitWidth = clog2(caseReps.count)
    items.append(.expr("if !traverser.skip(width: \(raw: kindBitWidth)) {$kind._traverse(using: &traverser)}"))
    if let contentBitWidthName = contentBitWidthName {
        items.append(.expr("if !traverser.skip(width: Self.\(contentBitWidthName)) {$payload._traverse(using: &traverser)}"))
    }
    return "func _traverse(using traverser: inout some _WireTraverser) {\(items.buildList())}"
}

func buildRefBitInit(
    for caseReps: [WireEnumCaseRep],
    contentBitWidthName: TokenSyntax?,
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    items.append(.expr("self.$kind = .init(_byPoppingBits: &builder)"))
    if let contentBitWidthName = contentBitWidthName {
        items.append(.expr("self.$payload = .init(_byPoppingBits: &builder, length: Self.\(contentBitWidthName))"))
    }
    return "init(_byPoppingBits builder: inout some _WirePopper) {\(items.buildList())}"
}

func buildRefPortInit(
    for caseReps: [WireEnumCaseRep],
    contentBitWidthName: TokenSyntax?,
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    items.append(.decl("let kindName = _joinModuleName(base: parentName, suffix: \"kind\")"))
    items.append(.expr("self.$kind = .init(_byPartWith: kindName, body: body)"))
    if let contentBitWidthName = contentBitWidthName {
        items.append(.decl("let contentName = _joinModuleName(base: parentName, suffix: \"payload\")"))
        items.append(.expr("self.$payload = .init(_byPartWith: contentName, body: body, length: Self.\(contentBitWidthName))"))
    }
    return "init(_byPartWith parentName: String?, body: (String, Int) -> [_WireID]) {\(items.buildList())}"
}

func buildRefPortApplication(
    for caseReps: [WireEnumCaseRep],
    contentBitWidthName: TokenSyntax?,
    in context: some MacroExpansionContext
) -> DeclSyntax {
    var items: [CodeBlockItemSyntax.Item] = []
    items.append(.decl("let kindName = _joinModuleName(base: parentName, suffix: \"kind\")"))
    items.append(.expr("self.$kind._applyPerPart(parentName: kindName, body: body)"))
    if contentBitWidthName != nil {
        items.append(.decl("let contentName = _joinModuleName(base: parentName, suffix: \"payload\")"))
        items.append(.expr("self.$payload._applyPerPart(parentName: contentName, body: body)"))
    }
    return "func _applyPerPart(parentName: String?, body: (String, [_WireID]) -> Void) {\(items.buildList())}"
}

func buildRefInitializingDecl(
    kindBitWidth: Int,
    kindIndex: Int,
    for caseRep: borrowing WireEnumCaseRep,
    contentBitWidthName: TokenSyntax?,
    in context: some MacroExpansionContext
) -> DeclSyntax {

    if caseRep.members.isEmpty {
        var items: [CodeBlockItemSyntax.Item] = []
        items.append(.decl("let kind: UIntNRef<\(raw: kindBitWidth)> = \(raw: kindIndex)"))

        if let contentBitWidthName = contentBitWidthName {
            items.append(.decl("let content: _EnumRawBuffer = .init(length: Self.\(contentBitWidthName))"))
            items.append(.stmt("return .init(kind, content)"))
        } else {
            items.append(.stmt("return .init(kind)"))
        }

        return "static var \(caseRep.name): Self {\(items.buildList())}"
    } else {
        let contentBitWidthName = contentBitWidthName!

        var items: [CodeBlockItemSyntax.Item] = []
        items.append(.decl("let kind: UIntNRef<\(raw: kindBitWidth)> = \(raw: kindIndex)"))
        items.append(.decl("var content: _EnumRawBuffer = .init(length: Self.\(contentBitWidthName))"))
        items.append(.decl("var _index = 0"))
        for (index, member) in caseRep.members.enumerated() {
            items.append(.expr("content.change(to: $a\(raw: index), at: _index)"))
            items.append(.expr("_index += (\(member.synthType))._bitWidth"))
        }
        items.append(.stmt("return .init(kind, content)"))

        var list: [FunctionParameterSyntax] = []
        for (index, member) in caseRep.members.enumerated() {
            let clause: InitializerClauseSyntax? = if let value = member.defaultValue?.value {
                InitializerClauseSyntax(value: convertExpression(value, in: context))
            } else {
                nil
            }
            let param = FunctionParameterSyntax(
                firstName: member.firstName?.with(\.trailingTrivia, " ") ?? .wildcardToken(trailingTrivia: " "),
                secondName: "$a\(raw: index)",
                type: member.synthType,
                defaultValue: clause
            )
            list.append(param)
        }
        return "static func \(caseRep.name)(\(list.buildList())) -> Self {\(items.buildList())}"
    }
}

func buildRefKindTest(
    kindIndex: Int,
    for caseRep: borrowing WireEnumCaseRep,
    contentBitWidthName: TokenSyntax?,
    in context: some MacroExpansionContext
) -> DeclSyntax {
    let name = "$is_\(caseRep.name.text)"

    let expr: ExprSyntax = "$kind == \(raw: kindIndex)"

    return "var \(raw: name): BoolRef {\(expr)}"
}

func buildRefUnbindDecl(
    kindIndex: Int,
    for caseRep: borrowing WireEnumCaseRep,
    contentBitWidthName: TokenSyntax?,
    in context: some MacroExpansionContext
) -> [DeclSyntax] {

    var decls: [DeclSyntax] = []

    var offsetExpr: ExprSyntax = "0"

    for (index, member) in caseRep.members.enumerated() {
        let name = "$unbind_\(caseRep.name.text)_\(index)"

        // build getters
        var getItems: [CodeBlockItemSyntax.Item] = []
        getItems.append(.decl("let offset = \(offsetExpr)"))
        getItems.append(.decl("return $payload.obtain((\(member.synthType)).self, at: offset)"))

        // build setters
        var setItems: [CodeBlockItemSyntax.Item] = []
        setItems.append(.decl("let offset = \(offsetExpr)"))
        setItems.append(.decl("$payload.change(to: newValue, at: offset)"))

        decls.append("var \(raw: name): \(member.synthType) {get{\(getItems.buildList())}\nset{\(setItems.buildList())}}")
        offsetExpr = "\(offsetExpr) + (\(member.synthType)._bitWidth)"
    }

    return decls
}

func buildRefFreeUnbindTypeDecls(
    for caseReps: [WireEnumCaseRep],
    in context: some MacroExpansionContext
) -> [DeclSyntax] {

    var decls: [DeclSyntax] = []
    for caseRep in caseReps {
        for (index, member) in caseRep.members.enumerated() {
            decls.append("typealias _UnbindType_\(raw: caseRep.name.text)_\(raw: index) = \(member.synthType)")
        }
    }
    return decls
}

func buildRefFreeUnbindDecl(
    for caseReps: [WireEnumCaseRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {

    var cases: [SwitchCaseSyntax] = []

    for caseRep in caseReps {

        var items: [CodeBlockItemSyntax.Item] = []

        if !caseRep.members.isEmpty {
            var types: [ExprSyntax] = []
            for member in caseRep.members {
                types.append("\(raw: member.synthType).self")
            }
            let array = ArrayExprSyntax(expressions: types)
            items.append(.stmt("return $payload.get(under: \(array), at: index)"))
        } else {
            items.append(.stmt("fatalError(\"case \(raw: caseRep.name.text) has no members.\")"))
        }

        cases.append("case \"\(raw: caseRep.name.text)\":\(items.buildList())")
    }
    cases.append("default: fatalError(\"unexpected case name: \\(name).\")")

    return "func _unbind(name: String, index: Int) -> any Shimmers.WireRef {switch name {\(cases.buildList())}}"
}

func buildRefFreeUnbindTestDecl(
    for caseReps: [WireEnumCaseRep],
    in context: some MacroExpansionContext
) -> DeclSyntax {

    var cases: [SwitchCaseSyntax] = []

    for (index, caseRep) in caseReps.enumerated() {
        var items: [CodeBlockItemSyntax.Item] = []
        items.append(.stmt("return $kind == \(raw: index)"))
        cases.append("case \"\(raw: caseRep.name.text)\":\(items.buildList())")
    }
    cases.append("default: fatalError(\"unexpected case name: \\(name)\")\n")

    return "func _unbind_is(name: String) -> BoolRef {switch name {\(cases.buildList())}}"
}
