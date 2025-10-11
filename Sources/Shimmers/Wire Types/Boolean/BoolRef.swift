//
//  Shimmers/Wire Types/Boolean/BoolRef.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public typealias BitRef = BoolRef

public struct BoolRef: WireRef, ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool
    public typealias Base = Bool

    @usableFromInline
    internal let wireID: _WireID

    @inlinable
    public static var _bitWidth: Int { 1 }

    @inlinable
    public func _getBit(at index: Int) -> _WireID {
        return wireID
    }

    @inlinable
    public func _traverse(using traverser: inout some _WireTraverser) {
        traverser.visit(wire: wireID)
    }

    @inlinable
    public init(_ value: Bool) {
        wireID = .init(value)
    }

    @inlinable
    public init(booleanLiteral value: Bool) {
        wireID = .init(value)
    }

    @inlinable
    internal init(wireID: _WireID) {
        self.wireID = wireID
    }

    @inlinable
    public init(byPoppingBits builder: inout some _WirePopper) {
        self.wireID = builder.pop()
    }
}
