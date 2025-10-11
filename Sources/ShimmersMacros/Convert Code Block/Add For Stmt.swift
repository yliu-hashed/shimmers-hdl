//
//  ShimmersMacros/Convert Code Block/Add For Stmt.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func addForStmt(
    referencing stmt: ForStmtSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    info: CodeBlockInfo,
    in context: some MacroExpansionContext
) throws -> Set<ImplicitCondition> {
    let hint = getIterationHint(for: stmt, in: context)

    let loopID: String
    if let label = info.recentLabel {
        loopID = "_\(label.text)"
    } else {
        loopID = String(info.unique.get())
    }

    let brk: TokenSyntax = "_brk\(raw: loopID)"
    let cnt: TokenSyntax = "_cnt\(raw: loopID)"
    let itr: TokenSyntax = "_itr\(raw: loopID)"
    let ele: TokenSyntax = "_ele\(raw: loopID)"
    let track: TokenSyntax = "_id\(raw: loopID)"

    items.append(.decl("var \(track): UInt64? = nil"))
    items.append(.stmt("defer {_discardLoopHistory(for: \(track))}"))
    items.append(.decl("@_Local var \(brk): BoolRef = false"))

    // make iterator
    let convertedSequence: ExprSyntax = convertExpression(stmt.sequence, in: context).trimmed
    items.append(.decl("@_Local var \(itr) = (\(convertedSequence))._makeIterator()"))

    // create body
    var newItems: [CodeBlockItemSyntax.Item] = []

    // create new condition
    newItems.append(.decl("@_Local var \(ele) = \(itr).next()"))

    let loopCond = "\(info.implicitCondExprs.joined(by: "&&")) && !\(brk) && \(ele)._isValid"
    newItems.append(.decl("@_Local var _c: BoolRef = \(raw: loopCond)"))

    if let iden = stmt.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed {
        newItems.append(.decl("let \(iden) = \(ele)._unchecked_unwraped"))
    } else if stmt.pattern.is(WildcardPatternSyntax.self) {
    } else {
        let err = MacroExpansionErrorMessage("Pattern '\(stmt.pattern.syntaxNodeType)' is not yet supported in for loops")
        context.addDiagnostics(from: err, node: stmt.sequence)
    }

    let loc = context.location(of: stmt)
    newItems.append(.stmt("guard _proveLoop(_c, id: &\(track), hintMin: \(raw: hint.min ?? 0), hintMax: \(raw: String(describing: hint.max)), debugLoc: DebugLocation(file: \(loc?.file), line: \(loc?.line))) else { break }"))

    newItems.append(.decl("@_Local var \(cnt): BoolRef = !\(ele)._isValid"))

    // transfer body content
    let slice = ArraySlice(stmt.body.statements.toArray())
    let newInfo = info.withNew(implicitConds: [.brk(label: loopID), .cnt(label: loopID)], loopID: loopID)

    var newNewItems: [CodeBlockItemSyntax.Item] = []
    let reEvals = try addCodeList(
        referencing: slice,
        into: &newNewItems,
        info: newInfo,
        mayConflictDecl: true,
        in: context
    )

    let block = CodeBlockSyntax(statements: newNewItems.buildList())

    try addOptional(for: ["_c"], codeBlock: block, into: &newItems, in: context)

    items.append(.stmt("while true {\(newItems.buildList())}"))

    return reEvals.subtracting([.brk(label: loopID), .cnt(label: loopID)])
}
