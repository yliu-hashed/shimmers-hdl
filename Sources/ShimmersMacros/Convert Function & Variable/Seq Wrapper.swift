//
//  ShimmersMacros/Convert Function & Variable/Seq Wrapper.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildSequentialWrapper(
    name: borrowing FunctionNamingInfo,
    moduleInfo: borrowing DetachedModuleInfo
) throws -> DeclSyntax {
    assert(!moduleInfo.isStaticOrGlobal && moduleInfo.isMutating)

    // create port info and return type
    let (infoArray, returnTypeExpr) = makeDetachedModuleShapeInfos(for: moduleInfo, addSelfPort: false)

    var items: [CodeBlockItemSyntax.Item] = []
    items.append(.decl("let _name: String = \"\(raw: name.module)\""))
    items.append(.decl("let _uniqueName: String = \"\\(Self.self).\(raw: name.driver)\""))
    items.append(.expr("return _createSequentialWrapper(for: _name, uniqueName: _uniqueName, portInfos: \(infoArray), returning: \(returnTypeExpr), type: Self.self) {_addWaiting(\(raw: name.driver)())}"))

    let list = items.buildList()

    let signature = FunctionSignatureSyntax(
        parameterClause: .init(parameters: []),
        returnClause: ReturnClauseSyntax(
            arrow: .arrowToken(),
            type: TypeSyntax("_WaitableSynthJob")
        )
    )

    let decl = FunctionDeclSyntax(
        modifiers: [
            .init(name: .keyword(.private)),
            .init(name: .keyword(.static))
        ],
        name: .identifier(name.driver + "_seq_wrapper"),
        signature: signature,
        body: "{\(list)}"
    )
    return DeclSyntax(decl)
}
