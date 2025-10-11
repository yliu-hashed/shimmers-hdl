//
//  ShimmersMacros/Convert Code Block/Add Switch Stmt.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func addSwitchStmt(
    referencing stmt: SwitchExprSyntax,
    into items: inout [CodeBlockItemSyntax.Item],
    info: CodeBlockInfo,
    in context: some MacroExpansionContext
) throws -> Set<ImplicitCondition> {
    // build testing wire
    let numID = stmt.id.indexInTree.toOpaque()

    let switchID: String
    if let label = info.recentLabel {
        switchID = "_\(label.text)"
    } else {
        switchID = String(info.unique.get())
    }


    let valueName: TokenSyntax = .identifier("$value\(numID)")
    let takeWireName = "_brk\(switchID)"

    items.append(.decl("@_Local var \(raw: takeWireName): BoolRef = false"))

    let valueExpr = convertExpression(stmt.subject.trimmed, in: context)
    items.append(.decl("let \(valueName) = \(valueExpr)"))

    var reEvals: Set<ImplicitCondition> = []
    for (index, element) in stmt.cases.enumerated() {
        guard case .switchCase(let switchCaseSyntax) = element else {
            let err = MacroExpansionErrorMessage("Only switch cases are allowed.")
            context.addDiagnostics(from: err, node: element)
            return []
        }
        let label = switchCaseSyntax.label

        // convert case body
        var childItems: [CodeBlockItemSyntax.Item] = []

        let condExpr: ExprSyntax
        switch label {
        case .case(let labels):
            let matchCond = extractSwitchPattern(
                uniqueNumber: numID,
                caseIndex: index,
                valueName: valueName,
                pattern: labels,
                items: &items,
                prologue: &childItems,
                in: context
            )
            condExpr = "!\(raw: takeWireName) && (\(matchCond))"
        case .default(_):
            condExpr = "!\(raw: takeWireName)"
        }

        childItems.append(.expr("defer {\(raw: takeWireName) = true}"))

        let slice = ArraySlice(switchCaseSyntax.statements.toArray())
        let newInfo = info.withNew(implicitConds: [.brk(label: switchID)], switchID: switchID)

        let reEval = try addCodeList(
            referencing: slice,
            into: &childItems,
            info: newInfo,
            mayConflictDecl: true,
            in: context
        )
        reEvals.formUnion(reEval.subtracting([.brk(label: switchID)]))

        let codeBlock = CodeBlockSyntax(statements: childItems.buildList())

        try addOptional(for: info.implicitCondExprs + [condExpr], codeBlock: codeBlock, into: &items, in: context)
    }
    return reEvals
}
