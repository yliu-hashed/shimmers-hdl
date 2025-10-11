//
//  ShimmersMacros/Convert Code Block/Add If Guard Stmt.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func addIfStmt(
    referencing stmt: IfExprSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    info: CodeBlockInfo,
    in context: some MacroExpansionContext
) throws -> Set<ImplicitCondition> {
    // build triggered wire
    let takeWireName = "_take\(stmt.id.indexInTree.toOpaque())"
    items.append(.decl("@_Local var \(raw: takeWireName): BoolRef = false"))

    // grab all conditions
    var conditions: [ConditionElementSyntax.Condition] = []
    for element in stmt.conditions {
        conditions.append(element.condition)
    }

    // build body and if layers
    let body = ArraySlice(stmt.body.statements.toArray())
    var reEval: Set<ImplicitCondition> = []
    let ifReEval = try addIfLayer(
        for: body, into: &items,
        restConds: ArraySlice(conditions),
        takeWireName: takeWireName,
        info: info, in: context
    )
    reEval.formUnion(ifReEval)

    // build else condition
    if let elseBody = stmt.elseBody {
        var newList: [CodeBlockItemSyntax.Item] = []
        let elReEval: Set<ImplicitCondition>
        switch elseBody {
        case .codeBlock(let block):
            let slice = ArraySlice(block.statements.toArray())
            elReEval = try addCodeList(
                referencing: slice, into: &newList,
                info: info, mayConflictDecl: false, in: context
            )
        case .ifExpr(let nestedIfExpr):
            elReEval = try addIfStmt(
                referencing: nestedIfExpr, into: &newList,
                info: info, in: context
            )
        }
        let block = CodeBlockSyntax(statements: newList.buildList())

        let conds = info.implicitCondExprs + ["!\(raw: takeWireName)"]
        try addOptional(for: conds, codeBlock: block, into: &items, in: context)
        reEval.formUnion(elReEval)
    }

    return reEval
}

func addGuardStmt(
    referencing stmt: GuardStmtSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    rest: inout ArraySlice<CodeBlockItemSyntax.Item>,
    info: CodeBlockInfo,
    in context: some MacroExpansionContext
) throws -> Set<ImplicitCondition> {
    // build triggered wire
    let takeWireName = "_pass\(stmt.id.indexInTree.toOpaque())"
    items.append(.decl("@_Local var \(raw: takeWireName): BoolRef = false"))

    // grab all conditions
    var conditions: [ConditionElementSyntax.Condition] = []
    for element in stmt.conditions {
        conditions.append(element.condition)
    }

    // build body and passing if layers
    var reEval: Set<ImplicitCondition> = []
    let ifReEval = try addIfLayer(
        for: rest, into: &items,
        restConds: ArraySlice(conditions),
        takeWireName: takeWireName,
        info: info, in: context
    )
    reEval.formUnion(ifReEval)
    rest.removeAll()

    // build guard fail condition
    let body = ArraySlice(stmt.body.statements.toArray())
    var newList: [CodeBlockItemSyntax.Item] = []
    let elReEval = try addCodeList(
        referencing: body,
        into: &newList,
        info: info,
        mayConflictDecl: false,
        in: context
    )
    let block = CodeBlockSyntax(statements: newList.buildList())

    let conds = info.implicitCondExprs + ["!\(raw: takeWireName)"]
    try addOptional(for: conds, codeBlock: block, into: &items, in: context)
    reEval.formUnion(elReEval)

    return reEval
}

func addIfLayer(
    for body: ArraySlice<CodeBlockItemSyntax.Item>,
    into items: inout [CodeBlockItemSyntax.Item],
    restConds: ArraySlice<ConditionElementSyntax.Condition>,
    takeWireName: String,
    info: CodeBlockInfo,
    in context: some MacroExpansionContext
) throws -> Set<ImplicitCondition> {
    guard let cond = restConds.first else {
        items.append(.expr("\(raw: takeWireName) = true"))
        return try addCodeList(
            referencing: body, into: &items,
            info: info, mayConflictDecl: true, in: context
        )
    }

    let uniqueNumber = cond.id.indexInTree.toOpaque()

    var newItems: [CodeBlockItemSyntax.Item] = []
    let condExpr: ExprSyntax
    switch cond {
    case .expression(let expr):
        condExpr = expr.trimmed
    case .matchingPattern(let cond):
        guard let cond = extractConditionalPattern(
            uniqueNumber: uniqueNumber,
            cond: cond,
            items: &items,
            prologue: &newItems,
            in: context
        ) else { return [] }
        condExpr = cond
    case .availability(let availability):
        let err = MacroExpansionErrorMessage("Availability condition is not supported in any synthesizable portion")
        context.addDiagnostics(from: err, node: availability)
        return []
    default:
        let err = MacroExpansionErrorMessage("Condition '\(cond.syntaxNodeType)' is not yet supported")
        context.addDiagnostics(from: err, node: cond)
        return []
    }
    let reEval = try addIfLayer(
        for: body, into: &newItems, restConds: restConds.dropFirst(),
        takeWireName: takeWireName, info: info, in: context
    )
    let codeBlock = CodeBlockSyntax(statements: newItems.buildList())

    try addOptional(for: info.implicitCondExprs + [condExpr], codeBlock: codeBlock, into: &items, in: context)
    return reEval
}
