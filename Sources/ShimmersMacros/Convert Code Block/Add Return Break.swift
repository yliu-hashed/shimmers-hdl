//
//  ShimmersMacros/Convert Code Block/Add Return Break.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func addReturnStmt(
    referencing stmt: ReturnStmtSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    in context: some MacroExpansionContext
) throws -> ImplicitCondition {
    if let expr = stmt.expression {
        let newExpr = convertExpression(expr.trimmed, in: context)
        items.append(.expr("_retVal = (\(newExpr))"))
    }
    items.append(.expr("_ret = true"))
    return .ret
}

func addBreakStmt(
    referencing stmt: BreakStmtSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    info: CodeBlockInfo,
    in context: some MacroExpansionContext
) throws -> ImplicitCondition {
    let label = stmt.label?.text ?? info.recentBrk!
    items.append(.expr("_brk\(raw: label) = true"))
    return .brk(label: label)
}

func addContinueStmt(
    referencing stmt: ContinueStmtSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    info: CodeBlockInfo,
    in context: some MacroExpansionContext
) throws -> ImplicitCondition {
    let label = stmt.label?.text ?? info.recentCnt!
    items.append(.expr("_cnt\(raw: label) = true"))
    return .cnt(label: label)
}
