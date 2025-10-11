//
//  ShimmersMacros/Attribute.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func containsSimOnly(attributes: AttributeListSyntax) -> Bool {
    for element in attributes {
        guard let attribute = element.as(AttributeSyntax.self) else { continue }
        if attribute.attributeName.trimmedDescription == "SimOnly" {
            return true
        }
    }
    return false
}
