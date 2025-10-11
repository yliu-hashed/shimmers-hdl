//
//  ShimmersMacros/Convert Wire Enum/Wire Enum Member Survey.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct WireEnumCaseRep {
    var name: TokenSyntax
    var members: [WireEnumCaseMemberRep]
}

struct WireEnumCaseMemberRep {
    var firstName: TokenSyntax?
    var name: TokenSyntax?
    var valueType: TypeSyntax
    var synthType: TypeSyntax
    var defaultValue: InitializerClauseSyntax?
}

func extractDataCases(
    for decl: EnumCaseDeclSyntax,
    into cases: inout [WireEnumCaseRep],
    isAssociated: inout Bool,
    names: inout Set<String>,
    in context: some MacroExpansionContext
) {
    guard !containsSimOnly(attributes: decl.attributes) else { return }

    for element in decl.elements {
        let name = element.name.trimmed

        guard !names.contains(name.text) else {
            let err = MacroExpansionErrorMessage("Enum case '\(name.text)' is duplicated. Shimmers cannot handle duplicate names.")
            context.addDiagnostics(from: err, node: element.name)
            continue
        }
        names.update(with: name.text)

        var members: [WireEnumCaseMemberRep] = []
        for param in element.parameterClause?.parameters ?? [] {
            let refType = convert(type: param.type, in: context)

            let member = WireEnumCaseMemberRep(
                firstName: param.firstName?.trimmed,
                name: param.secondName?.trimmed,
                valueType: param.type,
                synthType: refType.trimmed,
                defaultValue: param.defaultValue
            )

            members.append(member)
        }

        if !members.isEmpty {
            isAssociated = true
        }

        cases.append(WireEnumCaseRep(name: name, members: members))
    }
}
