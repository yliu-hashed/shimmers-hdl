//
//  ShimmersMacros/Convert Function & Variable/Convert Init.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildInit(
    for decl: InitializerDeclSyntax,
    in context: some MacroExpansionContext
) throws -> DeclSyntax? {
    guard !containsSimOnly(attributes: decl.attributes) else { return nil }

    guard decl.optionalMark == nil else {
        let mark = decl.optionalMark!
        let err = MacroExpansionErrorMessage("Optional initializer is not supported by Shimmers")
        context.addDiagnostics(from: err, node: mark)
        return nil
    }

    // make sure there's no function effects
    let origSignature = decl.signature
    if let effect = origSignature.effectSpecifiers {
        let err = MacroExpansionErrorMessage("'\(effect.trimmed)' is not supported by Shimmers")
        context.addDiagnostics(from: err, node: effect)
    }

    var paramInfos: [DetachedParameterInfo] = []
    var parameters: [FunctionParameterSyntax] = []

    // convert parameter clause
    for origParam in origSignature.parameterClause.parameters {
        try convertParameter(
            parameter: origParam,
            in: context,
            paramInfos: &paramInfos,
            parameters: &parameters
        )
    }
    let paramList = FunctionParameterListSyntax {
        for param in parameters {
            param
        }
    }
    let paramClause = FunctionParameterClauseSyntax(parameters: paramList)

    // build signature
    let newSig = FunctionSignatureSyntax(parameterClause: paramClause)

    // build body
    let newBody: CodeBlockSyntax
    if let body = decl.body {
        let loc = CodeListDebugInfo(
            name: "init",
            entry: context.location(of: body.leftBrace)
        )

        let newCodeList = try convertFullCodeList(
            for: body.statements,
            returnRefType: nil,
            isMutating: true,
            at: loc,
            in: context
        )
        newBody = CodeBlockSyntax(statements: newCodeList)
    } else {
        let err = MacroExpansionErrorMessage("'@HardwareWire' function must have an body")
        context.addDiagnostics(from: err, node: origSignature)
        newBody = CodeBlockSyntax(statements: [])
    }

    // create generator
    let generator = InitializerDeclSyntax(
        modifiers: decl.modifiers.trimmed,
        genericParameterClause: decl.genericParameterClause,
        signature: newSig,
        genericWhereClause: decl.genericWhereClause,
        body: newBody
    )

    return DeclSyntax(generator)
}
