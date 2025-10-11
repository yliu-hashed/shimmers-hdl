//
//  ShimmersMacros/Convert Function & Variable/Convert Function.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildGenFunc(
    for decl: FunctionDeclSyntax,
    isGlobal: Bool,
    in context: some MacroExpansionContext
) throws -> [DeclSyntax] {
    guard !containsSimOnly(attributes: decl.attributes) else { return [] }

    let pureName = decl.name.trimmed.text
    let detachedInfo = extractFunctionAttributeInfo(attributes: decl.attributes, isGlobal: isGlobal, in: context)
    let genName = detachedInfo.isDetached ? "$\(pureName)" : pureName
    let pureFullName = getFunctionName(decl: decl)

    var isMutating = false
    var isStaticOrGlobal = isGlobal
    for modifier in decl.modifiers {
        switch modifier.name.tokenKind {
        case .keyword(.mutating):
            isMutating = true
        case .keyword(.static):
            isStaticOrGlobal = true
        default:
            break
        }
    }

    // make sure there's no function effects
    let origSignature = decl.signature
    if let effect = origSignature.effectSpecifiers {
        let err = MacroExpansionErrorMessage("Effect specifier '\(effect.trimmed)' is not supported by Shimmers")
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

    let paramClause = FunctionParameterClauseSyntax(parameters: parameters.buildList())

    // build return clause
    let returnRefType: TypeSyntax?
    let returnClause: ReturnClauseSyntax?
    if let origReturnClause = origSignature.returnClause {
        returnRefType = convert(type: origReturnClause.type, in: context)
        returnClause = ReturnClauseSyntax(type: returnRefType!)
    } else {
        returnRefType = nil
        returnClause = nil
    }

    // build signature
    let newSig = FunctionSignatureSyntax(
        parameterClause: paramClause,
        returnClause: returnClause
    )

    // build body
    let newBody: CodeBlockSyntax
    if let body = decl.body {
        let loc = CodeListDebugInfo(
            name: pureFullName,
            entry: context.location(of: body.leftBrace)
        )
        let newCodeList = try convertFullCodeList(
            for: body.statements,
            returnRefType: returnRefType,
            isMutating: isMutating,
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
    let generator = FunctionDeclSyntax(
        modifiers: decl.modifiers.trimmed,
        name: TokenSyntax.identifier(genName),
        genericParameterClause: decl.genericParameterClause,
        signature: newSig,
        genericWhereClause: decl.genericWhereClause,
        body: newBody
    )
    var generators: [DeclSyntax] = [ DeclSyntax(generator) ]

    let driverName = context.makeUniqueName(pureName).text
    let bestModuleName = detachedInfo.name ?? pureName

    let namingInfo = FunctionNamingInfo(
        pure: pureName,
        pureFull: pureFullName,
        combModule: detachedInfo.isSequential ? bestModuleName + " helper" : bestModuleName,
        module: bestModuleName,
        generator: genName,
        driver: driverName
    )

    let moduleInfo = DetachedModuleInfo(
        arguments: paramInfos,
        returnType: returnRefType,
        isMutating: isMutating,
        isStaticOrGlobal: isStaticOrGlobal,
        isGlobal: isGlobal
    )

    // create stub generator for detached functions
    if detachedInfo.isDetached {
        let stubBody = try buildStubCodeList(
            name: namingInfo,
            moduleInfo: moduleInfo,
        )

        let stub = FunctionDeclSyntax(
            modifiers: decl.modifiers.trimmed,
            name: TokenSyntax.identifier(pureName),
            genericParameterClause: decl.genericParameterClause,
            signature: newSig,
            genericWhereClause: decl.genericWhereClause,
            body: stubBody
        )

        generators.append(DeclSyntax(stub))
    }

    if detachedInfo.isDetached || detachedInfo.isTopLevel {
        let detachedGeneratror = try buildDetached(
            name: namingInfo,
            moduleInfo: moduleInfo,
            genericParameterClause: decl.genericParameterClause,
            genericWhereClause: decl.genericWhereClause
        )

        generators.append(DeclSyntax(detachedGeneratror))
    }

    if detachedInfo.isTopLevel {
        if detachedInfo.isSequential { // sequential
            guard !isGlobal, isMutating else {
                let err = MacroExpansionErrorMessage("'@TopLevel' sequential function must be a mutating member function")
                context.addDiagnostics(from: err, node: decl.funcKeyword)
                return []
            }
            let wrapper = try buildSequentialWrapper(name: namingInfo, moduleInfo: moduleInfo)
            let entry = try buildTopLevelEntry(name: namingInfo, suffix: "_seq_wrapper", isGlobal: false)
            generators.append(wrapper)
            generators.append(entry)
        } else { // combinational
            let entry = try buildTopLevelEntry(name: namingInfo, isGlobal: moduleInfo.isGlobal)
            generators.append(entry)
        }
    }

    return generators
}

struct FunctionNamingInfo {
    /// The name of the function representing this detached module
    var pure: String
    /// Function full name
    var pureFull: String

    /// The name for the module responsible for the combinational portion of the module
    var combModule: String
    /// The external name for the module
    var module: String

    /// The name given for the function that actually generates the hardware
    var generator: String
    /// The driver
    var driver: String
}

func convertParameter(
    parameter: FunctionParameterListSyntax.Element,
    in context: some MacroExpansionContext,
    paramInfos: inout [DetachedParameterInfo],
    parameters: inout [FunctionParameterSyntax]
) throws {
    // create param
    let newType = convert(type: parameter.type, in: context)
    let param = FunctionParameterSyntax(
        firstName: parameter.firstName,
        secondName: parameter.secondName,
        type: newType
    )
    parameters.append(param)

    // create info
    let wrappedType: TypeSyntax
    let isInOut: Bool
    if let attributed = newType.as(AttributedTypeSyntax.self),
       attributed.specifiers.contains(where: { $0.trimmedDescription == "inout" }) {
        isInOut = true
        wrappedType = attributed.baseType
    } else {
        isInOut = false
        wrappedType = newType
    }
    let name = parameter.secondName ?? parameter.firstName
    let callName: TokenSyntax?
    if parameter.firstName.tokenKind != .wildcard {
        callName = parameter.firstName
    } else {
        callName = nil
    }
    let info = DetachedParameterInfo(
        name: name,
        callName: callName,
        synthType: wrappedType,
        isInOut: isInOut
    )
    paramInfos.append(info)
}
