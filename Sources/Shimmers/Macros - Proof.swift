//
//  Shimmers/Macros - Proof.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

/// Ensure that a value is always true during both runtime and synthesis.
@freestanding(expression)
public macro assert(
    _ condition: Bool,
    type: AssertionType = .assert,
    _ message: String? = nil
) = #externalMacro(
    module: "ShimmersMacros",
    type: "AssertMacro"
)

/// Assume that a value is always true during both runtime and synthesis.
@freestanding(expression)
public macro assume(
    _ condition: Bool,
    type: AssertionType = .assumption,
    _ message: String? = nil
) = #externalMacro(
    module: "ShimmersMacros",
    type: "AssumeMacro"
)

/// Ensure that a code path is never visited during both runtime and synthesis.
@freestanding(expression)
public macro never(
    type: AssertionType = .never,
    _ message: String? = nil
) -> Never = #externalMacro(
    module: "ShimmersMacros",
    type: "NeverMacro"
)
