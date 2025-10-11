//
//  ShimmersMacros/Convert Function & Variable/Stub Code List.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildStubCodeList(
    name: borrowing FunctionNamingInfo,
    moduleInfo: borrowing DetachedModuleInfo,
) throws -> CodeBlockSyntax {

    // create port info for all port passing into builder
    var infos: [ExprSyntax] = []
    if !moduleInfo.isStaticOrGlobal {
        infos.append(".init(value: self, name: \"self\", isMutable: \(raw: moduleInfo.isMutating))")
    }
    for arg in moduleInfo.arguments {
        infos.append(".init(value: \(arg.name), name: \"\(arg.name)\", isMutable: \(raw: arg.isInOut))")
    }
    let infoArray = ArrayExprSyntax(expressions: infos)

    // create return type
    let returnTypeExpr: ExprSyntax
    if let returnType = moduleInfo.returnType {
        returnTypeExpr = "(\(returnType)).self"
    } else {
        returnTypeExpr = "nil"
    }

    var items: [CodeBlockItemSyntax.Item] = []
    let driverName = moduleInfo.isGlobal ? name.driver : "Self.\(name.driver)"
    items.append(.expr("_addWaiting(\(raw: driverName)())"))
    items.append(.decl("let _name: String = \"\(raw: name.combModule)\""))
    items.append(.decl("let (_ret, _arr) = _insertDetached(name: _name, portInfos: \(infoArray), returning: \(returnTypeExpr))"))
    items.append(.expr("_ = _ret"))
    items.append(.expr("_ = _arr"))

    var index = 0
    if moduleInfo.isMutating {
        items.append(.expr("self = _arr[0] as! Self"))
        index += 1
    }
    for arg in moduleInfo.arguments where arg.isInOut {
        items.append(.expr("\(arg.name) = _arr[\(raw: index)] as! (\(arg.synthType))"))
        index += 1
    }

    if moduleInfo.returnType != nil {
        items.append(.expr("return _ret as! \(moduleInfo.returnType)"))
    } else {
        items.append(.expr("let _ = _ret"))
    }

    let superList = items.buildList()
    return "{\(superList)}"
}
