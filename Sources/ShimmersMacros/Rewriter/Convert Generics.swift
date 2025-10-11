//
//  ShimmersMacros/Rewriter/Convert Generics.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildGenericList(
    for generics: GenericParameterListSyntax,
    in context: some MacroExpansionContext
) throws -> GenericParameterListSyntax {
    return Rewriter(in: context).visit(generics).trimmed
}
