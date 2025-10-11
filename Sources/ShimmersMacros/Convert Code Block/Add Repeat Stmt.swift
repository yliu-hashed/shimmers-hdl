//
//  ShimmersMacros/Convert Code Block/Add Repeat Stmt.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func addRepeatStmt(
    referencing stmt: RepeatStmtSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    info: CodeBlockInfo,
    in context: some MacroExpansionContext
) throws -> Set<ImplicitCondition> {
    let hint = getIterationHint(for: stmt, in: context)
    let hintMin = (hint.min ?? 1) - 1
    let hintMax: String
    if let max = hint.max {
        hintMax = (max - 1).description
    } else {
        hintMax = "nil"
    }

    let loopID: String
    if let label = info.recentLabel {
        loopID = "_\(label.text)"
    } else {
        loopID = String(info.unique.get())
    }

    let brk: TokenSyntax = "_brk\(raw: loopID)"
    let cnt: TokenSyntax = "_cnt\(raw: loopID)"
    let track: TokenSyntax = "_id\(raw: loopID)"

    items.append(.decl("var \(track): UInt64? = nil"))
    items.append(.stmt("defer {_discardLoopHistory(for: \(track))}"))
    items.append(.decl("@_Local var \(brk): BoolRef = false"))

    // create new condition
    let convertedCond: ExprSyntax = convertExpression(stmt.condition, in: context).trimmed

    // create body
    var newItems: [CodeBlockItemSyntax.Item] = []
    newItems.append(.decl("@_Local var \(cnt): BoolRef = false"))

    // transfer body content
    let slice = ArraySlice(stmt.body.statements.toArray())
    let newInfo = info.withNew(implicitConds: [.brk(label: loopID), .cnt(label: loopID)], loopID: loopID)

    var newNewItems: [CodeBlockItemSyntax.Item] = []
    let reEvals = try addCodeList(
        referencing: slice,
        into: &newNewItems,
        info: newInfo,
        mayConflictDecl: false,
        in: context
    )
    let block = CodeBlockSyntax(statements: newNewItems.buildList())

    try addOptional(for: info.implicitCondExprs + ["!\(brk)"], codeBlock: block, into: &newItems, in: context)

    newItems.append(.expr("\(brk) = \(brk) || !(\(convertedCond))"))

    let proveCond = (info.implicitCondExprs + ["!\(brk)"]).joined(by: "&&")
    let loc = context.location(of: stmt)
    newItems.append(.stmt("guard _proveLoop(\(proveCond), id: &\(track), hintMin: \(raw: hintMin), hintMax: \(raw: hintMax), debugLoc: DebugLocation(file: \(loc?.file), line: \(loc?.line))) else { break }"))

    items.append(.stmt("while true {\(newItems.buildList())}"))
    return reEvals.subtracting([.brk(label: loopID), .cnt(label: loopID)])
}
