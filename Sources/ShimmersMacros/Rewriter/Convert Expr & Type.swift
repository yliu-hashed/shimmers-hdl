//
//  ShimmersMacros/Rewriter/Convert Expr & Type.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func convertExpression(
    _ expr: ExprSyntax,
    in context: some MacroExpansionContext
) -> ExprSyntax {
    return Rewriter(in: context).visit(expr).trimmed
}

func convert(
    type: TypeSyntax,
    in context: some MacroExpansionContext
) -> TypeSyntax {
    return Rewriter(in: context).visit(type).trimmed
}
