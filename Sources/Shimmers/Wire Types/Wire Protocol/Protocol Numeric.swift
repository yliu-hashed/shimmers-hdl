//
//  Shimmers/Wire Types/Wire Protocol/Protocol Numeric.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol NumericRef: AdditiveArithmeticRef, ExpressibleByIntegerLiteral {

    @available(*, deprecated, renamed: "Self.exactly(_:)")
    init<T: BinaryIntegerRef>(exactly source: T)

    static func exactly<T: BinaryIntegerRef>(_ source: T) -> OptionalRef<Self>

    associatedtype MagnitudeRef: ComparableRef, NumericRef
    var magnitude: MagnitudeRef { get }

    static func * (lhs: Self, rhs: Self) -> Self
    static func *= (lhs: inout Self, rhs: Self)
}

public extension NumericRef {
    init<T: BinaryIntegerRef>(exactly source: T) {
        // NOTE: due to technical reasons, BinaryIntegerRef cannot have a OptionalRef<BinaryIntegerRef> initializer.
        fatalError("init(exactly:) is not supported by Shimmers, use '.exactly(_:)' instead.")
    }
}

public protocol SignedNumericRef: NumericRef {
    static prefix func - (rhs: Self) -> Self
    mutating func negate()
}

public extension SignedNumericRef {
    static prefix func - (rhs: Self) -> Self {
        var result = rhs
        result.negate()
        return result
    }

    mutating func negate() {
        return self = 0 - self
    }
}

@inlinable
public func abs<T>(_ x: T) -> T where T : ComparableRef & SignedNumericRef {
    @_Local var result: T = x
    _if(x < (0 as T)) {
        result = -x
    }
    return result
}
