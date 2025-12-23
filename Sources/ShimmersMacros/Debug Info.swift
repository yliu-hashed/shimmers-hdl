//
//  ShimmersMacros/Debug Info.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros

func buildDebugLocation(from loc: AbstractSourceLocation?) -> ExprSyntax {
    guard let loc else { return "nil" }
    return "DebugLocation(file: \(loc.file), line: \(loc.line))"
}
