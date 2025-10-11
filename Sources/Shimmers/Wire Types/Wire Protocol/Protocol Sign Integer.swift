//
//  Shimmers/Wire Types/Wire Protocol/Protocol Sign Integer.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol UnsignedIntegerRef: BinaryIntegerRef {
}

public protocol SignedIntegerRef: BinaryIntegerRef, SignedNumericRef {
}

public extension UnsignedIntegerRef {
    @inlinable
    var magnitude: Self {
        return self
    }

    @inlinable
    static var isSigned: BoolRef { false }

    @inlinable
    static var _isSigned: Bool { false }
}

public extension SignedIntegerRef {
    @inlinable
    static var isSigned: BoolRef { true }

    @inlinable
    static var _isSigned: Bool { true }
}

public extension UnsignedIntegerRef where Self: FixedWidthIntegerRef {
    init<T: BinaryIntegerRef>(_ source: T) {
        _unsafeScopeIsolated { scope in
            if T._isSigned {
                scope.proveAssert(source >= T.zero, type: .overflowConvert, msg: "Negative value is not representable")
            }
            if source._bitWidth >= Self._bitWidth {
                scope.proveAssert(source <= Self.max, type: .overflowConvert, msg: "Not enough bits to represent the passed value")
            }
        }
        self.init(truncatingIfNeeded: source)
    }

    static var max: Self {
        return ~0
    }

    static var min: Self {
        return 0
    }

    static func exactly<T: BinaryIntegerRef>(_ source: T) -> OptionalRef<Self> {
        var isNone: BoolRef = false
        if T._isSigned {
            isNone = (source < T.zero)
        }
        isNone = isNone || (source.bitWidth > Self.bitWidth && source > Self.max)

        @_Local var result: OptionalRef<Self> = nil
        _if(!isNone) {
            let value = Self(truncatingIfNeeded: source)
            result = OptionalRef(wrapped: value)
        }
        return result
    }
}

public extension SignedIntegerRef where Self: FixedWidthIntegerRef {
    init<T: BinaryIntegerRef>(_ source: T) {
        _unsafeScopeIsolated { scope in
            if T._isSigned && source._bitWidth > Self._bitWidth {
                scope.proveAssert(source >= Self.min, type: .overflowConvert, msg: "Not enough bits to represent a signed value")
            }

            if (source._bitWidth > Self._bitWidth) ||
                (source._bitWidth == Self._bitWidth && !T._isSigned) {
                scope.proveAssert(source <= Self.max, type: .overflowConvert, msg: "Not enough bits to represent the passed value")
            }
        }
        self.init(truncatingIfNeeded: source)
    }

    static var max: Self {
        return ~min
    }

    static var min: Self {
        var builder = _NegativeOneWirePopper(width: Self._bitWidth)
        return Self(byPoppingBits: &builder)
    }

    @inlinable
    func isMultiple(of other: Self) -> BoolRef {
        @_Local var result: BoolRef = (self % other) == 0
        _if(other == 0) {
            result = self == 0
        }
        _if(other == -1) {
            result = true
        }
        return result
    }

    static func exactly<T: BinaryIntegerRef>(_ source: T) -> OptionalRef<Self> {
        var isNone: BoolRef = false
        if T._isSigned {
            isNone = (source.bitWidth > Self.bitWidth && source < Self.min)
        }
        if T._isSigned {
            isNone = isNone || (source.bitWidth > Self.bitWidth && source > Self.max)
        } else {
            isNone = isNone || (source.bitWidth >= Self.bitWidth && source > Self.max)
        }

        @_Local var result: OptionalRef<Self> = nil
        _if(!isNone) {
            let value = Self(truncatingIfNeeded: source)
            result = OptionalRef(wrapped: value)
        }
        return result
    }
}
