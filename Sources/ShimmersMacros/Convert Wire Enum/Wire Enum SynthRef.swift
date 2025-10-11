//
//  ShimmersMacros/Convert Wire Enum/Wire Enum SynthRef.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func buildSynthRefEnum(
    for enumDecl: EnumDeclSyntax,
    flatten: Bool,
    in context: some MacroExpansionContext
) throws -> StructDeclSyntax {

    // add all inheritances
    var inherts: [InheritedTypeSyntax] = []

    let refProtocolInheritance = InheritedTypeSyntax(
        type: TypeSyntax("Shimmers._EnumWireRef"),
        trailingComma: .commaToken()
    )
    inherts.append(refProtocolInheritance)

    inherts[inherts.endIndex - 1].trailingComma = nil

    let inhertList = InheritedTypeListSyntax(inherts)
    let inhertClause = InheritanceClauseSyntax(inheritedTypes: inhertList)

    // build all generics
    let genericClause: GenericParameterClauseSyntax?
    if let oldGenerics = enumDecl.genericParameterClause?.parameters {
        let list = try buildGenericList(for: oldGenerics, in: context)
        genericClause = GenericParameterClauseSyntax(parameters: list)
    } else {
        genericClause = nil
    }

    // build cases
    var names: Set<String> = []
    var members: [MemberBlockItemSyntax] = []
    var caseReps: [WireEnumCaseRep] = []
    var isAssociated: Bool = false

    // survey the struct
    for member in enumDecl.memberBlock.members {
        switch member.decl.kind {
        case .enumCaseDecl:
            let decl = member.decl.cast(EnumCaseDeclSyntax.self)
            extractDataCases(
                for: decl,
                into: &caseReps,
                isAssociated: &isAssociated,
                names: &names,
                in: context
            )
        default:
            continue
        }
    }

    guard !caseReps.isEmpty else {
        throw MacroExpansionErrorMessage("Must have at least one case.")
    }

    // build functions
    for member in enumDecl.memberBlock.members {
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
            let decls = try buildVariable(for: decl, noStorage: true, in: context)
            for decl in decls {
                members.append(MemberBlockItemSyntax(decl: DeclSyntax(decl)))
            }
        case .initializerDecl:
            let decl = member.decl.cast(InitializerDeclSyntax.self)
            guard let decl = try buildInit(for: decl, in: context) else { continue }
            members.append(MemberBlockItemSyntax(decl: decl))
        case .enumCaseDecl:
            continue
        default:
            let err = MacroExpansionErrorMessage("Unsupported declaration '\(member.decl.kind)'")
            context.addDiagnostics(from: err, node: member.decl)
        }
    }

    let contentBitWidthName: TokenSyntax? = isAssociated ? context.makeUniqueName("contentBitWidth") : nil

    // add basic members

    let kindBitWidth = clog2(caseReps.count)
    let kindDecl: DeclSyntax = "private let $kind: UIntNRef<\(raw: kindBitWidth)>"
    members.append(MemberBlockItemSyntax(decl: kindDecl))

    if contentBitWidthName != nil {
        let contentDecl: DeclSyntax = "private var $payload: _EnumRawBuffer"
        members.append(MemberBlockItemSyntax(decl: contentDecl))

        let initDecl: DeclSyntax = "private init(_ $kind: UIntNRef<\(raw: kindBitWidth)>, _ $payload: _EnumRawBuffer) {self.$kind = $kind\nself.$payload = $payload}"
        members.append(MemberBlockItemSyntax(decl: initDecl))
    } else {
        let initDecl: DeclSyntax = "private init(_ $kind: UIntNRef<\(raw: kindBitWidth)>) {self.$kind = $kind}"
        members.append(MemberBlockItemSyntax(decl: initDecl))
    }

    // build bit length

    let bitLengthDecl = buildRefBitLength(for: caseReps, contentBitWidthName: contentBitWidthName, in: context)
    members.append(MemberBlockItemSyntax(decl: bitLengthDecl))

    if let contentBitWidthName = contentBitWidthName {
        let bitContentLengthDecl = buildRefContentBitLength(for: caseReps, contentBitWidthName: contentBitWidthName, in: context)
        members.append(MemberBlockItemSyntax(decl: bitContentLengthDecl))
    }

    let bitTraverser = buildRefWireTraverser(for: caseReps, contentBitWidthName: contentBitWidthName, in: context)
    members.append(MemberBlockItemSyntax(decl: bitTraverser))

    let bitInit = buildRefBitInit(for: caseReps, contentBitWidthName: contentBitWidthName, in: context)
    members.append(MemberBlockItemSyntax(decl: bitInit))

    if !flatten {
        let portInit = buildRefPortInit(for: caseReps, contentBitWidthName: contentBitWidthName, in: context)
        members.append(MemberBlockItemSyntax(decl: portInit))

        let portResult = buildRefPortApplication(for: caseReps, contentBitWidthName: contentBitWidthName, in: context)
        members.append(MemberBlockItemSyntax(decl: portResult))
    }

    for (index, caseRep) in caseReps.enumerated() {
        // build initializing static declarations
        let decl = buildRefInitializingDecl(kindBitWidth: kindBitWidth, kindIndex: index, for: caseRep, contentBitWidthName: contentBitWidthName, in: context)
        members.append(MemberBlockItemSyntax(decl: decl))

        // build initializing
        let testDecl = buildRefKindTest(kindIndex: index, for: caseRep, contentBitWidthName: contentBitWidthName, in: context)
        members.append(MemberBlockItemSyntax(decl: testDecl))

        if caseRep.members.count > 0 {
            let unbindDecl = buildRefUnbindDecl(kindIndex: index, for: caseRep, contentBitWidthName: contentBitWidthName, in: context)
            let decls = unbindDecl.map({ MemberBlockItemSyntax(decl: $0) })
            members.append(contentsOf: decls)
        }
    }

    let freeUnbindDecl = buildRefFreeUnbindDecl(for: caseReps, in: context)
    members.append(MemberBlockItemSyntax(decl: freeUnbindDecl))

    let freeUnbindTestDecl = buildRefFreeUnbindTestDecl(for: caseReps, in: context)
    members.append(MemberBlockItemSyntax(decl: freeUnbindTestDecl))

    let freeUnbindTypes = buildRefFreeUnbindTypeDecls(for: caseReps, in: context)
    let freeUnbindTypeDecls = freeUnbindTypes.map({ MemberBlockItemSyntax(decl: $0) })
    members.append(contentsOf: freeUnbindTypeDecls)

    let memberList = MemberBlockItemListSyntax(members)
    let memberBlock = MemberBlockSyntax(members: memberList)

    let newStructTypeName = enumDecl.name.text + "Ref"
    let synthRef = StructDeclSyntax(
        modifiers: enumDecl.modifiers,
        name: .identifier(newStructTypeName),
        genericParameterClause: genericClause,
        inheritanceClause: inhertClause,
        memberBlock: memberBlock
    )

    return synthRef.trimmed
}
