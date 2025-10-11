//
//  Shimmers/Runtime/InlineArray.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public typealias Bus = InlineArray

extension InlineArray: Wire where Element: Wire {
    public static var bitWidth: Int {
        return count * Element.bitWidth
    }

    public func bit(at index: Int) -> Bool {
        let elementWidth = Element.bitWidth
        let elementIndex = index / elementWidth
        return self[elementIndex].bit(at: index % elementWidth)
    }

    public func _traverse(using traverser: inout some _BitTraverser) {
        for i in 0..<count {
            if traverser.skip(width: Element.bitWidth) { continue }
            self[i]._traverse(using: &traverser)
        }
    }

    public init(byPoppingBits source: inout some _BitPopper) {
        self.init { index in
            return .init(byPoppingBits: &source)
        }
    }

    public subscript (_ index: some BinaryInteger & FixedWidthInteger) -> Element {
        get {
            let i = Index(index)
            assert(indices.contains(i), "Index out of range.")
            return self[unchecked: i]
        }
        set {
            let i = Index(index)
            assert(indices.contains(i), "Index out of range.")
            self[unchecked: i] = newValue
        }
    }
}

extension Array {
    subscript (index: some BinaryInteger & FixedWidthInteger) -> Element {
        get {
            let i = Int(index)
            return self[i]
        }
        set {
            let i = Int(index)
            self[i] = newValue
        }
    }
}
