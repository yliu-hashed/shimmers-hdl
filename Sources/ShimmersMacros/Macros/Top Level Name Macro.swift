//
//  ShimmersMacros/Macros/Top Level Name Macro.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct TopLevelNameMacro: ExpressionMacro {
    static func decodeParam(
        of node: borrowing some FreestandingMacroExpansionSyntax,
        in context: borrowing some MacroExpansionContext
    ) throws -> (type: ExprSyntax?, name: String) {
        var type: ExprSyntax? = nil
        var name: String? = nil

        var arguments = node.arguments.reversed().map { $0 }

        if let arg = arguments.last, arg.label?.text == "name" {
            arguments.removeLast()
            guard let literal = arg.expression.as(StringLiteralExprSyntax.self),
                  let text = literal.representedLiteralValue else {
                throw MacroExpansionErrorMessage("Name parameter must be a string literal")
            }
            name = text
        } else {
            throw MacroExpansionErrorMessage("Missing name parameter")
        }

        if let arg = arguments.last, arg.label?.text == "of" {
            arguments.removeLast()
            if !arg.expression.is(NilLiteralExprSyntax.self) {
                var rawType = convertExpression(arg.expression, in: context)
                while let access = rawType.as(MemberAccessExprSyntax.self),
                      access.declName.baseName.text == "self",
                      let base = access.base {
                    rawType = base
                }
                type = rawType
            }
        }

        if let arg = arguments.last {
            throw MacroExpansionErrorMessage("Extra argument \(arg)")
        }

        guard let name = name else {
            throw MacroExpansionErrorMessage("Incorrect argument")
        }
        return (type, name)
    }

    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {

        let (type, name) = try decodeParam(of: node, in: context)
        let nameType = createDetachedTypeName(moduleName: name)

        let comments = "/* You have incorrect name if this doesn't exist */"

        if let type = type {
            return "\(type.trimmed).\(raw: nameType).self \(raw: comments)"
        } else {
            return "\(raw: nameType).self \(raw: comments)"
        }
    }
}
