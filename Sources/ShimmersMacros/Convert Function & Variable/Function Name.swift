//
//  ShimmersMacros/Convert Function & Variable/Function Name.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros

func getFunctionName(decl: FunctionDeclSyntax) -> String {
    var name = decl.name.text
    let param = decl.signature.parameterClause
    name += "("
    for param in param.parameters {
        name += param.firstName.text + ":"
    }
    name += ")"
    return name
}
