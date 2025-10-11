//
//  Shimmers/Runtime/Integers/UIntN.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public struct UIntN<let __bitWidth: Int>: _StrictUInt, BinaryInteger, FixedWidthInteger, UnsignedInteger {
    public static var bitWidth: Int { __bitWidth }

    public typealias Magnitude = UIntN<__bitWidth>
    public typealias Stride = Int

    static var bigMax: BigInt {
        return (BigInt(1) << Self.bitWidth) - 1
    }

    var value: BigInt
}

public extension UIntN {
    typealias SignedCounterpart = IntN<__bitWidth>

    init(bitPattern: SignedCounterpart) {
        value = bitPattern.value
        value.truncatingUnsigned(to: __bitWidth)
    }
}

public extension UIntN {
    typealias IntegerLiteralType = StaticBigInt

    init(integerLiteral value: StaticBigInt) {
        self.value = BigInt(integerLiteral: value)
        precondition(self.value >= 0)
        precondition(self.value <= Self.bigMax)
    }

    init<T>(_truncatingBits source: T) where T : BinaryInteger {
        self.value = BigInt(source)
        value.truncatingUnsigned(to: Self.bitWidth)
    }
}

public extension UIntN {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.value < rhs.value
    }
}

public extension UIntN {
    typealias Words = [UInt]

    var words: [UInt] {
        return value.words
    }

    var byteSwapped: Self {
        fatalError("\(#function) not implemented")
    }
}
