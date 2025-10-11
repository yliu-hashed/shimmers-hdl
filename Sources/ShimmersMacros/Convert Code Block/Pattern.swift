//
//  ShimmersMacros/Convert Code Block/Pattern.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

enum PatternPathInfo {
    case enumCase(name: String, index: Int)
    case tupleElement(index: Int)
}

struct PatternUnbindInfo {
    var path: [PatternPathInfo]
    var specifier: TokenSyntax

    var keyPathExpr: ExprSyntax {
        return getKeyPathExpr(of: path)
    }
}

func getKeyPathExpr(of path: [PatternPathInfo]) -> ExprSyntax {
    var keyPath: ExprSyntax = "\\"
    for component in path {
        switch component {
        case .enumCase(let name, let index):
            keyPath = "\(keyPath).$unbind_\(raw: name)_\(raw: index)"
        case .tupleElement(let index):
            keyPath = "\(keyPath).\(raw: index)"
        }
    }
    return keyPath
}

func decodePattern(
    _ pattern: consuming any PatternSyntaxProtocol,
    host: consuming TokenSyntax,
    in context: some MacroExpansionContext
) -> (binder: ExprSyntax, unbinds: [String: PatternUnbindInfo])? {
    var unbinds: [String: PatternUnbindInfo] = [:]
    var path: [PatternPathInfo] = []
    guard let expr = decodePattern(
        pattern,
        into: &unbinds,
        with: nil,
        path: &path,
        host: host,
        in: context
    ) else {
        return nil
    }
    return (expr, unbinds)
}

private func decodePattern(
    _ syntax: any SyntaxProtocol,
    into unbinds: inout [String: PatternUnbindInfo],
    with specifier: TokenSyntax?,
    path: inout [PatternPathInfo],
    host: TokenSyntax,
    in context: some MacroExpansionContext
) -> ExprSyntax? {
    switch syntax.kind {
    case .valueBindingPattern:
        assert(specifier == nil)
        let pat = syntax.cast(ValueBindingPatternSyntax.self)
        let specifier = pat.bindingSpecifier
        return decodePattern(pat.pattern, into: &unbinds, with: specifier, path: &path, host: host, in: context)

    case .expressionPattern:
        let pat = syntax.cast(ExpressionPatternSyntax.self)
        return decodePattern(pat.expression, into: &unbinds, with: specifier, path: &path, host: host, in: context)

    case .patternExpr:
        let expr = syntax.cast(PatternExprSyntax.self)
        return decodePattern(expr.pattern, into: &unbinds, with: specifier, path: &path, host: host, in: context)

    case .identifierPattern:
        guard let specifier = specifier else {
            let err = MacroExpansionErrorMessage("Identifier used without binding specifier.")
            context.addDiagnostics(from: err, node: syntax)
            return nil
        }
        let expr = syntax.cast(IdentifierPatternSyntax.self)

        let info = PatternUnbindInfo(
            path: path,
            specifier: specifier
        )
        unbinds[expr.identifier.text] = info
        return ".identifier(name: \"\(raw: expr.identifier.text)\")"

    case .discardAssignmentExpr:
        return ".wildcard"

    case .functionCallExpr:
        let call = syntax.cast(FunctionCallExprSyntax.self)
        guard let access = call.calledExpression.as(MemberAccessExprSyntax.self),
              access.base == nil,
              access.declName.argumentNames == nil
        else {
            return ".value(\(call))"
        }

        let name = access.declName.baseName.text

        var patterns: [ExprSyntax] = []

        for (index, arg) in call.arguments.enumerated() {
            let expr = arg.expression
            path.append(.enumCase(name: name, index: index))
            defer { path.removeLast() }
            guard let pattern = decodePattern(expr, into: &unbinds, with: specifier, path: &path, host: host, in: context) else {
                return nil
            }
            patterns.append(pattern)
        }

        let array = ArrayExprSyntax(expressions: patterns)
        return ".function(name: \"\(raw: name)\", args: \(array))"

    case .memberAccessExpr:
        let access = syntax.cast(MemberAccessExprSyntax.self)
        guard access.base == nil,
              access.declName.argumentNames == nil
        else {
            return ".value(\(access))"
        }

        let name = access.declName.baseName.text

        return ".member(name: \"\(raw: name)\")"


    default:
        guard let expr = syntax as? ExprSyntaxProtocol else {
            let err = MacroExpansionErrorMessage("Unrecognized binding kind '\(syntax.kind)'.")
            context.addDiagnostics(from: err, node: syntax)
            return nil
        }

        if path.isEmpty {
            return ".value(\(expr), matching: \(host))"
        } else {
            let keyPath = getKeyPathExpr(of: path)
            return ".value(\(expr), of: \(host), with: \(keyPath))"
        }
    }
}
