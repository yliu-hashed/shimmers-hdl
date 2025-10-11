//
//  Shimmers/Runtime/Range.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension Range: Wire where Bound: Wire {
    @inlinable
    public static var bitWidth: Int {
        Bound.bitWidth * 2
    }

    public func _traverse(using traverser: inout some _BitTraverser) {
        if !traverser.skip(width: Bound.bitWidth) {
            lowerBound._traverse(using: &traverser)
        }
        if !traverser.skip(width: Bound.bitWidth) {
            upperBound._traverse(using: &traverser)
        }
    }

    public init(byPoppingBits source: inout some _BitPopper) {
        let lowerBound = Bound(byPoppingBits: &source)
        let upperBound = Bound(byPoppingBits: &source)
        self = lowerBound..<upperBound
    }
}
