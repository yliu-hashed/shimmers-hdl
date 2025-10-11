//
//  ShimmersMacros/Macros.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ShimmersPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        HardwareWireMacro.self,
        HardwareFunctionMacro.self,
        DetachedFunctionMacro.self,
        TopLevelNameMacro.self,
        SimBlockMacro.self,
        AssertMacro.self,
        NeverMacro.self,
        AssumeMacro.self,
        TopLevelFunctionMacro.self,
    ]
}
