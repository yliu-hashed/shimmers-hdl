//
//  Shimmers/Wire Types/Wire Protocol/Protocol Stridable.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol StrideableRef<StrideRef> : ComparableRef {

    associatedtype StrideRef : ComparableRef, SignedNumericRef

    func distance(to other: Self) -> StrideRef

    func advanced(by n: StrideRef) -> Self
}

public extension StrideableRef {
    @inlinable
    static func < (x: Self, y: Self) -> BoolRef {
        return x.distance(to: y) > 0
    }

    @inlinable
    static func == (x: Self, y: Self) -> BoolRef {
        return x.distance(to: y) == 0
    }
}
