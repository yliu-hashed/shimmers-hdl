//
//  Shimmers/Wire Types/Wire Protocol/Protocol Arithmetic.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol AdditiveArithmeticRef: EquatableRef {
    static var zero: Self { get }
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func += (lhs: inout Self, rhs: Self)
    static func -= (lhs: inout Self, rhs: Self)
}

public extension AdditiveArithmeticRef {
    static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }

    static prefix func + (x: Self) -> Self {
        return x
    }
}

public extension AdditiveArithmeticRef where Self: ExpressibleByIntegerLiteral {
    static var zero: Self {
        return 0
    }
}
