//
//  Shimmers/Runtime/Integers/IntN.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public struct IntN<let __bitWidth: Int>: _StrictSInt, BinaryInteger, FixedWidthInteger, SignedInteger {
    public static var bitWidth: Int { __bitWidth }

    public typealias Magnitude = UIntN<__bitWidth>
    public typealias Stride = Int

    static var bigMax: BigInt {
        return (BigInt(1) << (Self.bitWidth - 1)) - 1
    }

    static var bigMin: BigInt {
        return BigInt(-1) << (Self.bitWidth - 1)
    }

    var value: BigInt
}

public extension IntN {
    init(bitPattern: Magnitude) {
        value = bitPattern.value
        value.truncatingSigned(to: __bitWidth)
    }
}

public extension IntN {
    typealias IntegerLiteralType = StaticBigInt

    init(integerLiteral value: StaticBigInt) {
        self.value = BigInt(integerLiteral: value)
        precondition(self.value >= Self.bigMin)
        precondition(self.value <= Self.bigMax)
    }

    init<T>(_truncatingBits source: T) where T : BinaryInteger {
        self.value = BigInt(source)
        value.truncatingSigned(to: Self.bitWidth)
    }
}

public extension IntN {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.value < rhs.value
    }
}

public extension IntN {
    typealias Words = [UInt]

    var words: [UInt] {
        let wordCount = (Self.bitWidth + UInt.bitWidth - 1) / UInt.bitWidth
        var words = value.segments
        if words.count < Int(wordCount) {
            words.append(contentsOf: repeatElement(value.exten, count: wordCount - words.count))
        }
        return words
    }

    var byteSwapped: Self {
        fatalError("\(#function) not implemented")
    }
}
