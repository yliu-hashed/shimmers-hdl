//
//  ShimmersMacros/Convert Function & Variable/Parse Detached Attribute.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct DetachedParseInfo {
    var name: String?
    var isDetached: Bool
    var isTopLevel: Bool
    var isSequential: Bool

    fileprivate static var bad: DetachedParseInfo {
        return .init(name: nil, isDetached: false, isTopLevel: false, isSequential: false)
    }
}

func extractFunctionAttributeInfo(
    attributes: AttributeListSyntax,
    isGlobal: Bool,
    in context: some MacroExpansionContext
) -> DetachedParseInfo {

    var name: String?
    var isDetached: Bool = false
    var isTopLevel: Bool = false
    var isSequential: Bool = false

    for element in attributes {
        guard let attribute = element.as(AttributeSyntax.self) else { continue }
        let attrName = attribute.attributeName.trimmedDescription
        if attrName == "Detached" {
            guard !isDetached else {
                let err = MacroExpansionErrorMessage("Cannot have more than one '@Detached' macro")
                context.addDiagnostics(from: err, node: element)
                continue
            }
            isDetached = true
        }
        if attrName == "TopLevel" {
            guard !isTopLevel else {
                let err = MacroExpansionErrorMessage("Cannot have more than one '@TopLevel' macro")
                context.addDiagnostics(from: err, node: element)
                continue
            }
            isTopLevel = true
            let type = decodeAttributes(node: attribute, isGlobal: isGlobal, in: context)
            if let moduleName = type.name {
                name = moduleName
            }
            isSequential = type.isSequential
        }
    }

    return DetachedParseInfo(name: name, isDetached: isDetached, isTopLevel: isTopLevel, isSequential: isSequential)
}

private func decodeAttributes(
    node: AttributeSyntax,
    isGlobal: Bool,
    in context: some MacroExpansionContext
) -> (name: String?, isSequential: Bool) {
    var name: String? = nil
    var isSequential: Bool = false

    guard let args = node.arguments?.as(LabeledExprListSyntax.self) else {
        return (name, isSequential)
    }

    var arguments = args.reversed().map { $0 }

    if let arg = arguments.last, arg.label?.text == "name" {
        arguments.removeLast()
        if !arg.expression.is(NilLiteralExprSyntax.self) {
            guard !isGlobal else {
                let err = MacroExpansionErrorMessage("Global '@TopLevel' not have an explicit name. It's name will be the same as the function name.")
                context.addDiagnostics(from: err, node: arg)
                return (name, isSequential)
            }

            guard let stringLit = arg.expression.as(StringLiteralExprSyntax.self),
                  let string = stringLit.representedLiteralValue
            else {
                let err = MacroExpansionErrorMessage("Name parameter for '@TopLevel' must be a string literal or 'nil'.")
                context.addDiagnostics(from: err, node: arg)
                return (name, isSequential)
            }
            name = string

            if !string.allSatisfy({ $0.isASCII && ($0.isNumber || $0.isLetter || $0.isSymbol || $0 == "_") }) {
                let err = MacroExpansionErrorMessage("Invalid module name")
                context.addDiagnostics(from: err, node: arg)
            }
            if string.isEmpty {
                let err = MacroExpansionErrorMessage("Module name cannot be empty")
                context.addDiagnostics(from: err, node: arg)
            }
        }
    }

    if let arg = arguments.last, arg.label?.text == "isSequential" {
        arguments.removeLast()
        guard let boolLit = arg.expression.as(BooleanLiteralExprSyntax.self)?.literal else {
            let err = MacroExpansionErrorMessage("Argument 'isSequential' must be boolean literal 'true' or 'false'.")
            context.addDiagnostics(from: err, node: arg)
            return (name, isSequential)
        }
        isSequential = boolLit.tokenKind == .keyword(.true)
    }

    if !arguments.isEmpty {
        let err = MacroExpansionErrorMessage("Unsupported argument")
        context.addDiagnostics(from: err, node: arguments.last!)
    }

    return (name, isSequential)
}
