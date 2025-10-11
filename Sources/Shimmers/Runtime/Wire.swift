//
//  Shimmers/Runtime/Wire.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol Wire {
    static var bitWidth: Int { get }

    init(byPoppingBits source: inout some _BitPopper)
    func _traverse(using traverser: inout some _BitTraverser)
}

extension Wire {
    public func bit(at index: Int) -> Bool {
        var traverser = _SingleBitTraverser(index: index)
        _traverse(using: &traverser)
        return traverser.bit
    }

    internal init(from arr: consuming [Bool]) {
        var builder = _ArrayBitPopper(array: arr)
        self.init(byPoppingBits: &builder)
    }

    @inlinable
    internal func _getAllBits() -> [Bool] {
        var wires: [Bool] = []
        wires.reserveCapacity(Self.bitWidth)
        for index in 0..<Self.bitWidth {
            wires.append(bit(at: index))
        }
        return wires
    }

    /// Bitwise convert to another wire type.
    public func `as`<Target: Wire>(_ type: Target.Type) -> Target {
        let bits = _getAllBits()
        assert(type.bitWidth == bits.count)
        return .init(from: bits)
    }
}
