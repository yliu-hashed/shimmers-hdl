//
//  ShimmersMacros/Convert Code Block/Extract Pattern.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func extractConditionalPattern(
    uniqueNumber: UInt64,
    cond: consuming MatchingPatternConditionSyntax,
    items: inout [CodeBlockItemSyntax.Item],
    prologue: inout [CodeBlockItemSyntax.Item],
    in context: some MacroExpansionContext
) -> ExprSyntax? {

    let valueName: TokenSyntax = .identifier("$value\(uniqueNumber)")
    items.append(.decl("let \(valueName) = \(cond.initializer.value)"))

    guard let (binder, unbinds) = decodePattern(cond.pattern, host: valueName, in: context) else {
        return nil
    }

    let patternName: TokenSyntax = .identifier("$pattern\(uniqueNumber)")
    items.append(.decl("let \(patternName): _Pattern = \(binder)"))

    let matchName: TokenSyntax = .identifier("$match\(uniqueNumber)")
    items.append(.decl("let \(matchName) = \(patternName).match(\(valueName))"))

    // unbind items

    for (name, unbind) in unbinds {
        let expr: ExprSyntax = "\(matchName).get(\"\(raw: name)\", of: \(valueName), with: \(unbind.keyPathExpr))"

        switch unbind.specifier.tokenKind {
        case .keyword(.let):
            prologue.append(.decl("let \(raw: name) = \(expr)"))
        case .keyword(.var):
            prologue.append(.decl("@_Local var \(raw: name) = \(expr)"))
        default:
            let err = MacroExpansionErrorMessage("Unsupported specifier '\(unbind.specifier.text)'")
            context.addDiagnostics(from: err, node: unbind.specifier)
            return nil
        }
    }

    return "\(matchName).isMatch"
}

private struct MultiPatternUnbindInfo {
    var paths: [[PatternPathInfo]]
    var specifier: TokenSyntax

    init(name: TokenSyntax, paths: [[PatternPathInfo]], specifier: TokenSyntax) {
        self.paths = paths
        self.specifier = specifier
    }

    init(unbind: PatternUnbindInfo) {
        paths = [unbind.path]
        specifier = unbind.specifier
    }
}

func extractSwitchPattern(
    uniqueNumber: UInt64,
    caseIndex: Int,
    valueName: TokenSyntax,
    pattern: consuming SwitchCaseLabelSyntax,
    items: inout [CodeBlockItemSyntax.Item],
    prologue: inout [CodeBlockItemSyntax.Item],
    in context: some MacroExpansionContext
) -> ExprSyntax? {

    var binders: [ExprSyntax] = []
    var unbindTable: [String: MultiPatternUnbindInfo] = [:]

    for pattern in pattern.caseItems {
        guard let (binder, unbinds) = decodePattern(pattern.pattern, host: valueName, in: context) else {
            return nil
        }
        binders.append(binder)

        if unbindTable.isEmpty {
            for (name, unbind) in unbinds {
                unbindTable[name] = .init(unbind: unbind)
            }
        } else {
            guard unbindTable.count == unbinds.count else {
                let err = MacroExpansionErrorMessage("Binder has different number of pattern components")
                context.addDiagnostics(from: err, node: pattern.pattern)
                return nil
            }
            for (name, info) in unbinds {
                unbindTable[name]!.paths.append(info.path)
            }
        }
    }

    let patternName: TokenSyntax = .identifier("$pattern\(uniqueNumber)_\(caseIndex)")
    let binderArray = ArrayExprSyntax(expressions: binders)
    items.append(.decl("let \(patternName): _MultiPattern = _MultiPattern(patterns: \(binderArray))"))

    let matchName: TokenSyntax = .identifier("$match\(uniqueNumber)_\(caseIndex)")
    items.append(.decl("let \(matchName) = \(patternName).match(\(valueName))"))

    // unbind items

    for (name, unbind) in unbindTable {
        var keyPaths: [ExprSyntax] = []

        for path in unbind.paths {
            keyPaths.append(getKeyPathExpr(of: path))
        }

        let arrayExpr = ArrayExprSyntax(expressions: keyPaths)
        let expr: ExprSyntax = "\(matchName).get(\"\(raw: name)\", of: \(valueName), with: \(arrayExpr))"

        switch unbind.specifier.tokenKind {
        case .keyword(.let):
            prologue.append(.decl("let \(raw: name) = \(expr)"))
        case .keyword(.var):
            prologue.append(.decl("@_Local var \(raw: name) = \(expr)"))
        default:
            let err = MacroExpansionErrorMessage("Unsupported specifier '\(unbind.specifier.text)'")
            context.addDiagnostics(from: err, node: unbind.specifier)
            return nil
        }
    }

    return "\(matchName).isMatch"
}
