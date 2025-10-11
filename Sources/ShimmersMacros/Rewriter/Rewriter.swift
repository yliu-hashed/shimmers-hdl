//
//  ShimmersMacros/Rewriter/Rewriter.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

class Rewriter: SyntaxRewriter {
    let context: any MacroExpansionContext
    init(in context: some MacroExpansionContext) {
        self.context = context
    }

    public override func visit(_ expr: UnresolvedTernaryExprSyntax) -> ExprSyntax {
        fatalError("UnresolvedTernaryExprSyntax should be resolved in sequence expression")
    }

    public override func visit(_ expr: SequenceExprSyntax) -> ExprSyntax {
        let flattened = expr.elements.flatMap { (expr) -> [ExprSyntax] in
            switch expr.kind {
            case .unresolvedTernaryExpr:
                let ternary = UnresolvedTernaryExprSyntax(expr)!
                return [
                    " ><?>< ",
                    visit(ternary.thenExpression),
                    " ><|>< ",
                ]
            default:
                return [visit(expr)]
            }
        }

        return ExprSyntax(SequenceExprSyntax(elements: ExprListSyntax(flattened))).trimmed
    }

    public override func visit(_ expr: TernaryExprSyntax) -> ExprSyntax {
        let condExpr = visit(expr.condition.trimmed)
        let thenExpr = visit(expr.thenExpression.trimmed)
        let elseExpr = visit(expr.elseExpression.trimmed)
        let expr = ExprSyntax("\(condExpr) ><?>< \(thenExpr) ><|>< \(elseExpr)")
        return expr
    }

    public override func visit(_ expr: OptionalChainingExprSyntax) -> ExprSyntax {
        let err = MacroExpansionErrorMessage("Lone optional chaining is not supported")
        context.addDiagnostics(from: err, node: expr.questionMark)
        return super.visit(expr)
    }

    public override func visit(_ expr: MemberAccessExprSyntax) -> ExprSyntax {
        return convertOptionalChaining(on: ExprSyntax(expr))
    }

    public override func visit(_ expr: SubscriptCallExprSyntax) -> ExprSyntax {
        return convertOptionalChaining(on: ExprSyntax(expr))
    }

    public override func visit(_ expr: FunctionCallExprSyntax) -> ExprSyntax {
        return convertOptionalChaining(on: ExprSyntax(expr))
    }

    public override func visit(_ expr: ForceUnwrapExprSyntax) -> ExprSyntax {
        let core = visit(expr.expression).trimmed
        return ExprSyntax("(\(core))._checked_unwraped")
    }

    public override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        let converted = convertTypeToken(node.name)
        return super.visit(node.with(\.name, converted))
    }

    public override func visit(_ expr: DeclReferenceExprSyntax) -> ExprSyntax {
        guard expr.argumentNames == nil else { return ExprSyntax(expr) }
        let converted = convertTypeToken(expr.baseName)
        return super.visit(expr.with(\.baseName, converted))
    }

    public override func visit(_ node: GenericParameterSyntax) -> GenericParameterSyntax {
        if let specifier = node.specifier {
            assert(specifier.tokenKind == .keyword(.let))
            return node
        } else {
            return super.visit(node)
        }
    }

    public override func visit(_ node: OptionalTypeSyntax) -> TypeSyntax {
        let core = visit(node.wrappedType).trimmed
        return TypeSyntax("Shimmers.OptionalRef<\(core)>\(node.trailingTrivia)")
    }
}

func convertTypeToken(_ token: TokenSyntax) -> TokenSyntax {
    guard case .identifier(let name) = token.tokenKind else { return token }

    let converted: String
    if name == "Self" || name == "Any" || name.hasPrefix("ExpressibleBy") {
        converted = name
    } else {
        let isType = name.lazy.filter(\.isLetter).first?.isUppercase ?? false
        converted = isType ? name + "Ref" : name
    }
    return token.with(\.tokenKind, .identifier(converted))
}
