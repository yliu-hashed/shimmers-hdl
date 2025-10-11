//
//  Shimmers/Runtime/Enum Runtime Support.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public func _enum_pack<each T: Wire>(_ value: repeat each T, length: Int) -> [Bool] {
    var buffer = [Bool](repeating: false, count: length)
    var index: Int = 0
    for (item, width) in repeat (each value, (each T).bitWidth) {
        let range = index..<(index + width)
        buffer.replaceSubrange(range, with: item._getAllBits())
        index += width
    }
    return buffer
}

public func _enum_unpack<each T: Wire>(_ types: repeat (each T).Type, from popper: inout some _BitPopper, length: Int) -> (repeat each T) {
    var total: Int = 0
    for width in repeat (each T).bitWidth {
        total += width
    }
    defer { _ = popper.pop(count: length - total) }
    return (repeat (each T).init(byPoppingBits: &popper))
}
