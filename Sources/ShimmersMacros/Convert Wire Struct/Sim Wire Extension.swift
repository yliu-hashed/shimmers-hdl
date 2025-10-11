//
//  ShimmersMacros/Convert Wire Struct/Sim Wire Extension.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildWireExtention(
    for structDecl: StructDeclSyntax,
    in context: some MacroExpansionContext
) throws -> ExtensionDeclSyntax {
    // survey all the members of the struct
    var memberReps: [WireStructMemberRep] = []

    for member in structDecl.memberBlock.members {
        guard let decl = member.decl.as(VariableDeclSyntax.self) else { continue }
        extractDataMembers(for: decl, into: &memberReps, in: context)
    }

    guard !memberReps.isEmpty else {
        throw MacroExpansionErrorMessage("Must have at least one wire member.")
    }

    var items: [CodeBlockItemSyntax.Item] = []

    let bitLength = buildWireBitLength(for: memberReps, in: context)
    items.append(.decl(bitLength))

    let bitGrabber = buildWireBitTraverser(for: memberReps, in: context)
    items.append(.decl(bitGrabber))

    let bitInit = buildWireBitInit(for: memberReps, in: context)
    items.append(.decl(bitInit))


    let inhertList = InheritedTypeListSyntax {
        InheritedTypeSyntax(type: TypeSyntax("Shimmers.Wire"))
    }
    let inhertClause = InheritanceClauseSyntax(inheritedTypes: inhertList)

    return ExtensionDeclSyntax(
        extendedType: TypeSyntax("\(structDecl.name)"),
        inheritanceClause: inhertClause,
        memberBlock: "{\(items.buildList())}"
    )
}
