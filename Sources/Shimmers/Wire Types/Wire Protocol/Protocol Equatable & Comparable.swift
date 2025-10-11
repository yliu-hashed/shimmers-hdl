//
//  Shimmers/Wire Types/Wire Protocol/Protocol Equatable & Comparable.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol EquatableRef: WireRef {
    static func == (lhs: Self, rhs: Self) -> BoolRef
    static func != (lhs: Self, rhs: Self) -> BoolRef
}

public protocol ComparableRef: WireRef & EquatableRef {
    static func >  (lhs: Self, rhs: Self) -> BoolRef
    static func <  (lhs: Self, rhs: Self) -> BoolRef
    static func >= (lhs: Self, rhs: Self) -> BoolRef
    static func <= (lhs: Self, rhs: Self) -> BoolRef
}

public extension EquatableRef {
    @inlinable
    static func != (lhs: Self, rhs: Self) -> BoolRef {
        return !(lhs == rhs)
    }
}

public extension ComparableRef {
    @inlinable
    static func <= (lhs: Self, rhs: Self) -> BoolRef {
        return !(rhs < lhs)
    }

    @inlinable
    static func >= (lhs: Self, rhs: Self) -> BoolRef {
        return !(lhs < rhs)
    }

    @inlinable
    static func > (lhs: Self, rhs: Self) -> BoolRef {
        return rhs < lhs
    }
}
