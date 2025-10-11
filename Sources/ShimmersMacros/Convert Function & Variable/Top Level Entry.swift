//
//  ShimmersMacros/Convert Function & Variable/Top Level Entry.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func createDetachedTypeName(moduleName: String) -> String {
    return "_TopLevel_\(moduleName)"
}

func buildTopLevelEntry(
    name: borrowing FunctionNamingInfo,
    suffix: String = "",
    isGlobal: Bool,
) throws -> DeclSyntax {

    let typeName = createDetachedTypeName(moduleName: name.module)

    let warningTrivia = "\n/// DO NOT CALL THIS METHOD DIRECTLY\n"

    let nameStaticVar = try VariableDeclSyntax("static var name: String { \"\(raw: name.module)\" }")
    let generateFunction = try FunctionDeclSyntax("\(raw: warningTrivia)static func _generate() -> _WaitableSynthJob {\(raw: name.driver + suffix)()}")

    let items: [DeclSyntax] = [
        DeclSyntax(nameStaticVar),
        DeclSyntax(generateFunction)
    ]

    let decl: DeclSyntax = "enum \(raw: typeName): Shimmers.TopLevelGenerator {\(items.buildList())}"

    return decl
}
