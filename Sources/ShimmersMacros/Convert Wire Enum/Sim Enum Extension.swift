//
//  ShimmersMacros/Convert Wire Enum/Sim Enum Extension.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildWireExtention(
    for enumDecl: EnumDeclSyntax,
    in context: some MacroExpansionContext
) throws -> ExtensionDeclSyntax {
    // survey all the members of the struct
    var names: Set<String> = []
    var caseReps: [WireEnumCaseRep] = []
    var isAssociated: Bool = false

    for member in enumDecl.memberBlock.members {
        guard let decl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
        extractDataCases(
            for: decl,
            into: &caseReps,
            isAssociated: &isAssociated,
            names: &names,
            in: context
        )
    }
    names.removeAll()

    guard !caseReps.isEmpty else {
        throw MacroExpansionErrorMessage("Must have at least one case.")
    }

    var items: [CodeBlockItemSyntax.Item] = []

    let contentBitWidthName: TokenSyntax? = isAssociated ? context.makeUniqueName("contentBitWidth") : nil

    let bitLength = buildWireBitLength(for: caseReps, contentBitWidthName: contentBitWidthName, in: context)
    items.append(.decl(bitLength))

    if let contentBitWidthName = contentBitWidthName {
        let bitContentLength = buildWireContentBitLength(for: caseReps, contentBitWidthName: contentBitWidthName, in: context)
        items.append(.decl(bitContentLength))
    }

    let bitGrabber = buildWireBitTraverser(for: caseReps, contentBitWidthName: contentBitWidthName, in: context)
    items.append(.decl(bitGrabber))

    let bitInit = buildWireBitInit(for: caseReps, contentBitWidthName: contentBitWidthName, in: context)
    items.append(.decl(bitInit))


    let inhertList = InheritedTypeListSyntax {
        InheritedTypeSyntax(type: TypeSyntax("Shimmers.Wire"))
    }
    let inhertClause = InheritanceClauseSyntax(inheritedTypes: inhertList)

    return ExtensionDeclSyntax(
        extendedType: TypeSyntax("\(enumDecl.name)"),
        inheritanceClause: inhertClause,
        memberBlock: "{\(items.buildList())}"
    )
}
