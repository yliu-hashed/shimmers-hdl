//
//  Shimmers/Macros - Building.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

/// Construct wire representing a group of values using structs and enums.
@attached(extension, conformances: Shimmers.Wire, names: named(bitWidth), named(_traverse(using:)), named(init(byPoppingBits:)))
@attached(peer, names: suffixed(Ref))
public macro HardwareWire(
    flatten: Bool = false
) = #externalMacro(
    module: "ShimmersMacros",
    type: "HardwareWireMacro"
)

/// Allow a global to be used to represent hardware.
@attached(peer, names: overloaded, prefixed(`$`), prefixed(`_TopLevel_`))
public macro HardwareFunction() = #externalMacro(
    module: "ShimmersMacros",
    type: "HardwareFunctionMacro"
)

/// Synthesize a function out-of-place from the caller module.
@attached(peer)
public macro Detached(
) = #externalMacro(
    module: "ShimmersMacros",
    type: "DetachedFunctionMacro"
)

/// Marks that a function is a generator entry, and allows it to be directly synthesized.
@attached(peer)
public macro TopLevel(
    name moduleName: String? = nil,
    isSequential: Bool = false
) = #externalMacro(
    module: "ShimmersMacros",
    type: "TopLevelFunctionMacro"
)

/// Refer to a top level module.
@freestanding(expression)
public macro topLevel(
    name: String,
    of: (any Wire.Type)? = nil
) -> TopLevelGenerator.Type = #externalMacro(
    module: "ShimmersMacros",
    type: "TopLevelNameMacro"
)

/// Perform actions only during runtime simulation that does not participate in synthesis.
@freestanding(expression)
public macro sim(
    _ block: ()->Void
) = #externalMacro(
    module: "ShimmersMacros",
    type: "SimBlockMacro"
)
