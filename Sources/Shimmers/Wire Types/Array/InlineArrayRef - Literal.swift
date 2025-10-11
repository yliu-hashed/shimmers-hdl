//
//  Shimmers/Wire Types/Array/InlineArrayRef - Literal.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension InlineArrayRef: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = ElementRef

    public init(arrayLiteral elements: ElementRef...) {
        assert(elements.count == count)
        storage = elements
    }
}
