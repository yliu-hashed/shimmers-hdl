//
//  ShimmersMacros/Macros/Check Parent.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

func checkHardwareParent(
    attributes: AttributeListSyntax? = nil,
    in context: some MacroExpansionContext
) -> Bool {
    if let attributes = attributes {
        for attr in attributes {
            guard case .attribute(let attr) = attr else { continue }
            let desc = attr.attributeName.trimmedDescription
            if desc == "HardwareWire" {
                return true
            }
            if desc == "HardwareFunction" {
                return true
            }
        }
    }

    for syntax in context.lexicalContext {
        if let decl = syntax.as(StructDeclSyntax.self) {
            for attr in decl.attributes {
                guard case .attribute(let attr) = attr else { continue }
                let desc = attr.attributeName.trimmedDescription
                if desc == "HardwareWire" {
                    return true
                }
                if desc == "HardwareFunction" {
                    return true
                }
            }
        }
    }
    return false
}
