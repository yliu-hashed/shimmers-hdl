//
//  ShimmersMacros/Convert Code Block/Loop Hint.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics


func getIterationHint(
    for stmt: ForStmtSyntax,
    in context: some MacroExpansionContext
) -> ItrHint {
    let scopeLeftBrace = stmt.body.leftBrace
    return parseIntHint(scopeLeftBrace: scopeLeftBrace, in: context)
}

func getIterationHint(
    for stmt: WhileStmtSyntax,
    in context: some MacroExpansionContext
) -> ItrHint {
    let scopeLeftBrace = stmt.body.leftBrace
    return parseIntHint(scopeLeftBrace: scopeLeftBrace, in: context)
}

func getIterationHint(
    for stmt: RepeatStmtSyntax,
    in context: some MacroExpansionContext
) -> ItrHint {
    let scopeLeftBrace = stmt.body.leftBrace
    return parseIntHint(scopeLeftBrace: scopeLeftBrace, in: context)
}

struct ItrHint {
    var min: Int? = nil
    var max: Int? = nil
}

private func parseIntHint(scopeLeftBrace: TokenSyntax, in context: some MacroExpansionContext) -> ItrHint {
    let regex = #/:HINT\s+ITR\s+\((\d+)?,(\d+)?\)/#

    let triviaStr = scopeLeftBrace.trailingTrivia.description
    let matches = triviaStr.matches(of: regex)
    guard matches.count <= 1 else {
        let warning = MacroExpansionWarningMessage("Multiple iteration hint found, no hint will be used")
        let diag = Diagnostic(node: scopeLeftBrace, message: warning)
        context.diagnose(diag)
        return ItrHint()
    }
    guard let match = matches.first else { return ItrHint() }
    let minimum: Int?
    if let minSubs = match.output.1 {
        minimum = Int(minSubs)!
    } else {
        minimum = nil
    }
    let maximum: Int?
    if let minSubs = match.output.2 {
        maximum = Int(minSubs)!
    } else {
        maximum = nil
    }
    return ItrHint(min: minimum, max: maximum)
}
