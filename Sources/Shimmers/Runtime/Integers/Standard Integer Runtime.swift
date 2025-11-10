//
//  Shimmers/Runtime/Integers/Standard Integer Runtime.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension Int   : _StrictSInt {}
extension Int8  : _StrictSInt {}
extension Int16 : _StrictSInt {}
extension Int32 : _StrictSInt {}
extension Int64 : _StrictSInt {}

extension UInt   : _StrictUInt { public typealias SignedCounterpart = Int   }
extension UInt8  : _StrictUInt { public typealias SignedCounterpart = Int8  }
extension UInt16 : _StrictUInt { public typealias SignedCounterpart = Int16 }
extension UInt32 : _StrictUInt { public typealias SignedCounterpart = Int32 }
extension UInt64 : _StrictUInt { public typealias SignedCounterpart = Int64 }

public protocol _StrictSInt: Wire
where Self: FixedWidthInteger & Numeric & SignedInteger,
      Stride.Stride == Stride, Magnitude.Magnitude == Magnitude,
      Stride == Int, Magnitude: _StrictUInt {

    init(bitPattern: Magnitude)
}

public protocol _StrictUInt: Wire
where Self: FixedWidthInteger & Numeric & UnsignedInteger,
      Stride.Stride == Stride, Magnitude.Magnitude == Magnitude,
      Stride == Int, Magnitude == Self {

    associatedtype SignedCounterpart: _StrictSInt where SignedCounterpart.Magnitude == Self

    init(bitPattern: SignedCounterpart)
}

extension _StrictSInt {
    public func bit(at index: Int) -> Bool {
        assert(index >= 0 && index < Self.bitWidth)
        return ((self >> index) & 1) == 1
    }

    public func _traverse(using traverser: inout some _BitTraverser) {
        var value = self
        for _ in 0..<Self.bitWidth {
            let bit = (value & 1) == 1
            traverser.visit(bit: bit)
            value >>= 1
        }
    }

    public init(_byPoppingBits source: inout some _BitPopper) {
        var mag: Magnitude = 0
        let high: Magnitude = 1 << (Self.bitWidth - 1)
        for _ in 0..<Self.bitWidth {
            let mask = source.pop() ? high : 0
            mag = (mag >> 1) | mask
        }
        self.init(bitPattern: mag)
    }
}

extension _StrictUInt {
    public func bit(at index: Int) -> Bool {
        assert(index >= 0 && index < Self.bitWidth)
        return ((self >> index) & 1) == 1
    }

    public func _traverse(using traverser: inout some _BitTraverser) {
        var value = self
        for _ in 0..<Self.bitWidth {
            let bit = (value & 1) == 1
            traverser.visit(bit: bit)
            value >>= 1
        }
    }

    public init(_byPoppingBits source: inout some _BitPopper) {
        var mag: Magnitude = 0
        let high: Magnitude = 1 << (Self.bitWidth - 1)
        for _ in 0..<Self.bitWidth {
            let mask = source.pop() ? high : 0
            mag = (mag >> 1) | mask
        }
        self = mag
    }
}

public extension Numeric {
    static func exactly<T: BinaryInteger>(_ source: T) -> Optional<Self> {
        return Self(exactly: source)
    }
}
