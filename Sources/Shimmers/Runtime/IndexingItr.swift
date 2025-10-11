//
//  Shimmers/Runtime/IndexingItr.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension IndexingIterator: Wire where Elements: Wire, Elements.Index: Wire {

    @inlinable
    public static var bitWidth: Int {
        return Elements.bitWidth + Elements.Index.bitWidth
    }

    public init(byPoppingBits source: inout some _BitPopper) {
        fatalError("IndexingIterator doesn't have a known bit-level layout")
    }

    public func _traverse(using traverser: inout some _BitTraverser) {
        fatalError("IndexingIterator doesn't have a known bit-level layout")
    }
}
