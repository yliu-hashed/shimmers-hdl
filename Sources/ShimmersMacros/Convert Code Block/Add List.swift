//
//  ShimmersMacros/Convert Code Block/Add List.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics


@discardableResult
func addCodeList(
    referencing list: ArraySlice<CodeBlockItemSyntax.Item>,
    into items: inout [CodeBlockItemSyntax.Item],
    info: CodeBlockInfo,
    mayConflictDecl: Bool,
    in context: some MacroExpansionContext
) throws -> Set<ImplicitCondition> {
    if mayConflictDecl, !items.isEmpty {
        var newItems: [CodeBlockItemSyntax.Item] = []
        let reEvals = try addCodeList(
            referencing: list,
            into: &newItems,
            info: info,
            mayConflictDecl: false,
            in: context
        )
        items.append(.expr("{\(newItems.buildList())}()"))
        return reEvals
    }

    func addDebugInfo(of syntax: any SyntaxProtocol) {
        let loc = context.location(of: syntax)
        items.append(.expr("_frame.updateLocation(file: \(loc?.file), line: \(loc?.line))"))
    }

    var liveSlice = list
    var allReEval: Set<ImplicitCondition> = []
    loop: while allReEval.isEmpty, let item = liveSlice.popFirst() {
        addDebugInfo(of: item)
        switch item {
        case .decl(let decl):
            try addDecl(referencing: decl, into: &items, in: context)
        case .stmt(let stmt):
            allReEval = try addStmt(referencing: stmt, into: &items, rest: &liveSlice, info: info, in: context)
        case .expr(let expr):
            if let call = expr.as(MacroExpansionExprSyntax.self) {
                switch call.macroName.text {
                case "sim":
                    continue loop
                case "assert":
                    guard let (value, type, message) = AssertMacro.simpleDecodeParam(of: call) else { continue loop }
                    let loc = context.location(of: call)
                    items.append(.expr("_proveAssert(\(value), type: \(type), msg: \(message ?? "nil"), debugLoc: DebugLocation(file: \(loc?.file), line: \(loc?.line)))"))
                    continue loop
                case "assume":
                    guard let (value, type, message) = AssumeMacro.simpleDecodeParam(of: call) else { continue loop }
                    let loc = context.location(of: call)
                    items.append(.expr("_proveAssume(\(value), type: \(type), msg: \(message ?? "nil"), debugLoc: DebugLocation(file: \(loc?.file), line: \(loc?.line)))"))
                    continue loop
                case "never":
                    guard let (type, message) = NeverMacro.simpleDecodeParam(of: call) else { continue loop }
                    let loc = context.location(of: call)
                    items.append(.expr("_proveNever(type: \(type), msg: \(message ?? "nil"), debugLoc: DebugLocation(file: \(loc?.file), line: \(loc?.line)))"))
                    continue loop
                default: break
                }
            }
            items.append(.expr(convertExpression(expr, in: context)))
            allReEval = []
        }
    }

    if !liveSlice.isEmpty {
        var newList: [CodeBlockItemSyntax.Item] = []
        let reEval = try addCodeList(
            referencing: liveSlice, into: &newList,
            info: info, mayConflictDecl: false, in: context
        )
        let block = CodeBlockSyntax(statements: newList.buildList())
        try addOptional(for: info.implicitCondExprs, codeBlock: block, into: &items, in: context)
        allReEval.formUnion(reEval)
    }
    return allReEval
}

func addOptional(
    for conds: [ExprSyntax],
    codeBlock: CodeBlockSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    in context: some MacroExpansionContext
) throws {
    let cond = conds.descriptionJoined(by: ", ")
    let expr: ExprSyntax = "_if(\(raw: cond)) \(codeBlock)"
    items.append(.expr(expr))
}

private func addDecl(
    referencing decl: DeclSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    in context: some MacroExpansionContext
) throws {
    if let varDecl = decl.as(VariableDeclSyntax.self) {
        try addVarDecl(referencing: varDecl, into: &items, in: context)
    } else {
        let err = MacroExpansionErrorMessage("Declaration '\(decl.syntaxNodeType)' is not yet supported")
        context.addDiagnostics(from: err, node: decl)
    }
}

private func addStmt(
    referencing stmt: StmtSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    rest: inout ArraySlice<CodeBlockItemSyntax.Item>,
    info: CodeBlockInfo,
    in context: some MacroExpansionContext
) throws -> Set<ImplicitCondition> {
    switch stmt.kind {
    case .labeledStmt:
        let stmt = stmt.cast(LabeledStmtSyntax.self)
        let info = info.withRecentLabel(stmt.label)
        return try addStmt(referencing: stmt.statement, into: &items, rest: &rest, info: info, in: context)
    case .returnStmt:
        let stmt = stmt.cast(ReturnStmtSyntax.self)
        let reEval = try addReturnStmt(referencing: stmt, into: &items, in: context)
        return [reEval]
    case .breakStmt:
        let stmt = stmt.cast(BreakStmtSyntax.self)
        let reEval = try addBreakStmt(referencing: stmt, into: &items, info: info, in: context)
        return [reEval]
    case .continueStmt:
        let stmt = stmt.cast(ContinueStmtSyntax.self)
        let reEval = try addContinueStmt(referencing: stmt, into: &items, info: info, in: context)
        return [reEval]
    case .forStmt:
        let stmt = stmt.cast(ForStmtSyntax.self)
        return try addForStmt(referencing: stmt, into: &items, info: info, in: context)
    case .whileStmt:
        let stmt = stmt.cast(WhileStmtSyntax.self)
        return try addWhileStmt(referencing: stmt, into: &items, info: info, in: context)
    case .repeatStmt:
        let stmt = stmt.cast(RepeatStmtSyntax.self)
        return try addRepeatStmt(referencing: stmt, into: &items, info: info, in: context)
    case .guardStmt:
        let stmt = stmt.cast(GuardStmtSyntax.self)
        return try addGuardStmt(referencing: stmt, into: &items, rest: &rest, info: info, in: context)
    case .expressionStmt:
        let expr = stmt.cast(ExpressionStmtSyntax.self).expression
        switch expr.kind {
        case .ifExpr:
            let expr = expr.cast(IfExprSyntax.self)
            return try addIfStmt(referencing: expr, into: &items, info: info, in: context)
        case .switchExpr:
            let expr = expr.cast(SwitchExprSyntax.self)
            return try addSwitchStmt(referencing: expr, into: &items, info: info, in: context)
        default:
            let err = MacroExpansionErrorMessage("Expression statement of type '\(stmt.syntaxNodeType)' is not yet supported")
            context.addDiagnostics(from: err, node: stmt)
            return []
        }
    default:
        let err = MacroExpansionErrorMessage("Statement of type '\(stmt.syntaxNodeType)' is not yet supported")
        context.addDiagnostics(from: err, node: stmt)
        return []
    }
}
