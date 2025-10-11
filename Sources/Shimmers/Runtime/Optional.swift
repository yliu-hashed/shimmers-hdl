//
//  Shimmers/Runtime/Optional.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension Optional: Wire where Wrapped: Wire {
    @inlinable
    public static var bitWidth: Int {
        return Wrapped.bitWidth + 1
    }

    public func bit(at index: Int) -> Bool {
        assert(index >= 0 && index < Self.bitWidth)
        if index == 0 {
            return self != nil
        } else {
            return self?.bit(at: index) ?? false
        }
    }

    public func _traverse(using traverser: inout some _BitTraverser) {
        let isValid = self != nil
        traverser.visit(bit: isValid)
        if isValid {
            self!._traverse(using: &traverser)
        } else {
            for _ in 0..<Wrapped.bitWidth {
                traverser.visit(bit: false)
            }
        }
    }

    public init(byPoppingBits source: inout some _BitPopper) {
        let valid = Bool.init(byPoppingBits: &source)
        guard valid else {
            self = nil
            return
        }
        self = Wrapped(byPoppingBits: &source)
    }
}
