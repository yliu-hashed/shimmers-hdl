//
//  ShimmersMacros/Convert Function & Variable/Detached Generator.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct DetachedParameterInfo {
    var name: TokenSyntax
    var callName: TokenSyntax?
    var synthType: TypeSyntax
    var isInOut: Bool
}

struct DetachedModuleInfo {
    var arguments: [DetachedParameterInfo]
    var returnType: TypeSyntax?
    var isMutating: Bool
    var isStaticOrGlobal: Bool
    var isGlobal: Bool
}

func makeDetachedModuleShapeInfos(
    for moduleInfo: borrowing DetachedModuleInfo,
    addSelfPort: Bool = true
) -> (infoArray: ArrayExprSyntax, returnTypeExpr: ExprSyntax) {
    // create port info for all port passing into builder
    var infos: [ExprSyntax] = []
    if !moduleInfo.isStaticOrGlobal && addSelfPort {
        infos.append(".init(name: \"self\", type: Self.self, isMutable: \(raw: moduleInfo.isMutating))")
    }
    for arg in moduleInfo.arguments {
        infos.append(".init(name: \"\(arg.name)\", type: (\(arg.synthType)).self, isMutable: \(raw: arg.isInOut))")
    }
    let infoArray = ArrayExprSyntax(expressions: infos)

    // create return type
    let returnTypeExpr: ExprSyntax
    if let returnType = moduleInfo.returnType {
        returnTypeExpr = "(\(returnType)).self"
    } else {
        returnTypeExpr = "nil"
    }

    return (infoArray, returnTypeExpr)
}

func buildDetached(
    name: borrowing FunctionNamingInfo,
    moduleInfo: borrowing DetachedModuleInfo,
    genericParameterClause: GenericParameterClauseSyntax?,
    genericWhereClause: GenericWhereClauseSyntax?
) throws -> DeclSyntax {

    // create port info and return type
    let (infoArray, returnTypeExpr) = makeDetachedModuleShapeInfos(for: moduleInfo)

    var childItems: [CodeBlockItemSyntax.Item] = []

    // recover self from new argument (if not static)
    let indexOffset = moduleInfo.isStaticOrGlobal ? 0 : 1
    if !moduleInfo.isStaticOrGlobal {
        let selfDeclKeyword: TokenSyntax = .identifier(moduleInfo.isMutating ? "var" : "let")
        childItems.append(.decl("\(selfDeclKeyword) me = inputs[0] as! Self"))
    }

    // recover argument types
    for (index, arg) in moduleInfo.arguments.enumerated() {
        let declKeyword: TokenSyntax = .identifier(arg.isInOut ? "var" : "let")
        childItems.append(.decl("\(declKeyword) v\(raw: index) = inputs[\(raw: index + indexOffset)] as! (\(arg.synthType))"))
    }

    // call generator
    let callList = LabeledExprListSyntax {
        for (index, arg) in moduleInfo.arguments.enumerated() {
            let expr: ExprSyntax = arg.isInOut ? "&v\(raw: index)" : "v\(raw: index)"
            LabeledExprSyntax(label: arg.callName?.text, expression: expr)
        }
    }

    if moduleInfo.isStaticOrGlobal {
        assert(moduleInfo.returnType != nil)
        let generatorName: String = moduleInfo.isGlobal ? name.generator : "Self.\(name.generator)"
        childItems.append(.decl("let ret = \(raw: generatorName)(\(callList))"))
    } else if moduleInfo.returnType != nil {
        childItems.append(.decl("let ret = me.\(raw: name.generator)(\(callList))"))
    } else if !moduleInfo.isStaticOrGlobal {
        childItems.append(.expr("me.\(raw: name.generator)(\(callList))"))
    }

    var mutValues: [ExprSyntax] = []
    if moduleInfo.isMutating {
        mutValues.append("me")
    }
    for (index, arg) in moduleInfo.arguments.enumerated() where arg.isInOut {
        mutValues.append("v\(raw: index)")
    }
    let mutArray = ArrayExprSyntax(expressions: mutValues)

    if moduleInfo.returnType != nil {
        childItems.append(.stmt("return (ret, \(mutArray))"))
    } else {
        childItems.append(.stmt("return (nil, \(mutArray))"))
    }

    let childList = childItems.buildList()

    var items: [CodeBlockItemSyntax.Item] = []
    items.append(.decl("let _name: String = \"\(raw: name.combModule)\""))
    let uniqueName: String = moduleInfo.isGlobal ? "\(name.driver)" : "\\(Self.self).\(name.driver)"
    items.append(.decl("let _uniqueName: String = \"\(raw: uniqueName)\""))
    items.append(.expr("return _createDetached(for: _name, uniqueName: _uniqueName, portInfos: \(infoArray), returning: \(returnTypeExpr)) { inputs in \(childList)}"))

    let list = items.buildList()

    let signature = FunctionSignatureSyntax(
        parameterClause: .init(parameters: []),
        returnClause: ReturnClauseSyntax(
            arrow: .arrowToken(),
            type: TypeSyntax("_WaitableSynthJob")
        )
    )

    let modifiers: DeclModifierListSyntax
    if moduleInfo.isGlobal {
        modifiers = [
            .init(name: .keyword(.private))
        ]
    } else {
        modifiers = [
            .init(name: .keyword(.private)),
            .init(name: .keyword(.static))
        ]
    }

    let decl = FunctionDeclSyntax(
        modifiers: modifiers,
        name: .identifier(name.driver),
        genericParameterClause: genericParameterClause,
        signature: signature,
        genericWhereClause: genericWhereClause,
        body: "{\(list)}"
    )

    return DeclSyntax(decl)
}
