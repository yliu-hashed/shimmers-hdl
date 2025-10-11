//
//  ShimmersMacros/Convert Wire Struct/Wire Struct SynthRef.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildSynthRefStruct(
    for structDecl: StructDeclSyntax,
    flatten: Bool,
    in context: some MacroExpansionContext
) throws -> StructDeclSyntax {

    // add all inheritances
    var inherts: [InheritedTypeSyntax] = []

    let refProtocolInheritance = InheritedTypeSyntax(
        type: TypeSyntax("Shimmers.WireRef"),
        trailingComma: .commaToken()
    )
    inherts.append(refProtocolInheritance)

    inherts[inherts.endIndex - 1].trailingComma = nil

    let inhertList = InheritedTypeListSyntax(inherts)
    let inhertClause = InheritanceClauseSyntax(inheritedTypes: inhertList)

    // build all generics
    let genericClause: GenericParameterClauseSyntax?
    if let oldGenerics = structDecl.genericParameterClause?.parameters {
        let list = try buildGenericList(for: oldGenerics, in: context)
        genericClause = GenericParameterClauseSyntax(parameters: list)
    } else {
        genericClause = nil
    }

    // build member block
    var members: [MemberBlockItemSyntax] = []
    var memberReps: [WireStructMemberRep] = []
    var hasInit: Bool = false

    // survey the struct
    for member in structDecl.memberBlock.members {
        switch member.decl.kind {
        case .variableDecl:
            let decl = member.decl.cast(VariableDeclSyntax.self)
            extractDataMembers(for: decl, into: &memberReps, in: context)
        default:
            continue
        }
    }

    guard !memberReps.isEmpty else {
        throw MacroExpansionErrorMessage("Must have at least one wire member.")
    }

    // build functions
    for member in structDecl.memberBlock.members {
        switch member.decl.kind {
        case .functionDecl:
            let decl = member.decl.cast(FunctionDeclSyntax.self)
            guard !containsSimOnly(attributes: decl.attributes) else { continue }
            let decls = try buildGenFunc(for: decl, isGlobal: false, in: context)
            for decl in decls {
                members.append(MemberBlockItemSyntax(decl: DeclSyntax(decl)))
            }
        case .variableDecl:
            let decl = member.decl.cast(VariableDeclSyntax.self)
            let decls = try buildVariable(for: decl, in: context)
            for decl in decls {
                members.append(MemberBlockItemSyntax(decl: DeclSyntax(decl)))
            }
        case .initializerDecl:
            let decl = member.decl.cast(InitializerDeclSyntax.self)
            guard let decl = try buildInit(for: decl, in: context) else { continue }
            members.append(MemberBlockItemSyntax(decl: decl))
            hasInit = true
        default:
            let err = MacroExpansionErrorMessage("Unsupported declaration '\(member.decl.kind)'")
            context.addDiagnostics(from: err, node: member.decl)
        }
    }

    let virtualizer = buildVirtualizer(for: memberReps, in: context)
    members.append(MemberBlockItemSyntax(decl: virtualizer))

    let devirtualizer = buildDevirtualizer(for: memberReps, in: context)
    members.append(MemberBlockItemSyntax(decl: devirtualizer))

    let bitLengthDecl = buildRefBitLength(for: memberReps, in: context)
    members.append(MemberBlockItemSyntax(decl: bitLengthDecl))

    let bitTraverser = buildRefWireTraverser(for: memberReps, in: context)
    members.append(MemberBlockItemSyntax(decl: bitTraverser))

    let bitInit = buildRefBitInit(for: memberReps, in: context)
    members.append(MemberBlockItemSyntax(decl: bitInit))

    if !flatten {
        let portInit = buildRefPortInit(for: memberReps, in: context)
        members.append(MemberBlockItemSyntax(decl: portInit))

        let portResult = buildRefPortApplication(for: memberReps, in: context)
        members.append(MemberBlockItemSyntax(decl: portResult))
    }

    if !hasInit {
        let memberInit = buildMemberWiseInit(for: memberReps, in: context)
        members.append(MemberBlockItemSyntax(decl: memberInit))
    }

    let memberList = MemberBlockItemListSyntax(members)
    let memberBlock = MemberBlockSyntax(members: memberList)

    // build struct
    let newStructTypeName = structDecl.name.text + "Ref"
    let synthRef = StructDeclSyntax(
        modifiers: structDecl.modifiers,
        name: .identifier(newStructTypeName),
        genericParameterClause: genericClause,
        inheritanceClause: inhertClause,
        memberBlock: memberBlock
    )

    return synthRef.trimmed
}
