//
//  ShimmersMacros/Rewriter/Rewrite Optional Chaining.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

extension Rewriter {
    func convertOptionalChaining(on expr: ExprSyntax) -> ExprSyntax {
        var r: ExprSyntax? = expr
        var list: [ExprSyntax] = []
        while let root = r {
            let (expr, root) = helper(on: root, newRootName: "_root")
            r = root
            list.append(expr)
        }

        var outer = list.first!
        for item in list.dropFirst() {
            outer = "\(item)._chain({ _root in \(outer) })"
        }

        return outer
    }

    private func helper(on expr: ExprSyntax, newRootName: String) -> (expr: ExprSyntax, root: ExprSyntax?) {
        switch expr.kind {
        case .memberAccessExpr:
            let expr = MemberAccessExprSyntax(expr)!
            let name = DeclReferenceExprSyntax(visit(expr.declName))!
            if let base = expr.base {
                let (newBase, root) = helper(on: base, newRootName: newRootName)
                let result = MemberAccessExprSyntax(base: newBase, declName: name, trailingTrivia: expr.trailingTrivia)
                return (expr: ExprSyntax(result), root: root)
            } else {
                let result = MemberAccessExprSyntax(declName: name, trailingTrivia: expr.trailingTrivia)
                return (expr: ExprSyntax(result), root: nil)
            }
        case .subscriptCallExpr:
            let expr = SubscriptCallExprSyntax(expr)!
            let index = LabeledExprListSyntax(visit(expr.arguments))!
            let (newBase, root) = helper(on: expr.calledExpression, newRootName: newRootName)
            let result = SubscriptCallExprSyntax(calledExpression: newBase, arguments: index, trailingTrivia: expr.trailingTrivia)
            return (expr: ExprSyntax(result), root: root)
        case .functionCallExpr:
            let expr = FunctionCallExprSyntax(expr)!
            let index = LabeledExprListSyntax(visit(expr.arguments))!
            let (newBase, root) = helper(on: expr.calledExpression, newRootName: newRootName)
            var closure: ClosureExprSyntax? = nil
            if let closureExpr = expr.trailingClosure {
                closure = ClosureExprSyntax(visit(closureExpr))
            }
            let result = FunctionCallExprSyntax(
                calledExpression: newBase,
                leftParen: expr.leftParen,
                arguments: index,
                rightParen: expr.rightParen,
                trailingClosure: closure,
                additionalTrailingClosures: visit(expr.additionalTrailingClosures),
                trailingTrivia: expr.trailingTrivia
            )
            return (expr: ExprSyntax(result), root: root)
        case .optionalChainingExpr:
            let expr = OptionalChainingExprSyntax(expr)!
            return (expr: "\(raw: newRootName)", root: expr.expression)
        default:
            let visited = visit(expr)
            return (expr: visited, root: nil)
        }
    }
}
