//
//  Shimmers/Runtime/Bool.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public typealias Bit = Bool

extension Bool: Wire {
    @inlinable
    public static var bitWidth: Int { 1 }

    public init(byPoppingBits source: inout some _BitPopper) {
        self = source.pop()
    }

    public func _traverse(using traverser: inout some _BitTraverser) {
        traverser.visit(bit: self)
    }
}

extension Bool {
    @inlinable
    public func implies(_ other: @autoclosure ()->Bool) -> Bool {
        return !self || other()
    }

    @inlinable
    public func isImplied(by other: @autoclosure ()->Bool) -> Bool {
        return self || !other()
    }
}
