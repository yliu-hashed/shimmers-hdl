//
//  Shimmers/Runtime Support/BigInt/BigInt - Bitwise.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension BigInt {
    typealias Words = [UInt]

    var words: [UInt] {
        var words: [UInt] = segments
        if words.isEmpty { return [exten] }
        let mask: UInt = 1 << (UInt.bitWidth - 1)
        if words.last! & mask != exten & mask {
            words.append(exten)
        }
        return words
    }

    static func ^= (lhs: inout Self, rhs: Self) {
        let segmentCount = Swift.max(lhs.segments.count, rhs.segments.count)
        lhs.expand(to: rhs.segments.count)
        lhs.exten ^= rhs.exten
        for i in 0..<segmentCount {
            lhs.segments[i] ^= rhs.getSegment(i)
        }
        lhs.trim()
    }

    static func |= (lhs: inout Self, rhs: Self) {
        let segmentCount = Swift.max(lhs.segments.count, rhs.segments.count)
        lhs.expand(to: rhs.segments.count)
        lhs.exten |= rhs.exten
        for i in 0..<segmentCount {
            lhs.segments[i] |= rhs.getSegment(i)
        }
        lhs.trim()
    }

    static func &= (lhs: inout Self, rhs: Self) {
        let segmentCount = Swift.max(lhs.segments.count, rhs.segments.count)
        lhs.expand(to: rhs.segments.count)
        lhs.exten &= rhs.exten
        for i in 0..<segmentCount {
            lhs.segments[i] &= rhs.getSegment(i)
        }
        lhs.trim()
    }

    static prefix func ~ (x: borrowing BigInt) -> BigInt {
        return .init(exten: ~x.exten, segments: x.segments.map(~))
    }

    static func <<= <RHS>(lhs: inout BigInt, rhs: RHS) where RHS : BinaryInteger {
        let amount = Int(rhs)
        assert(amount >= 0, "Shifting left by a negative amount is not allowed")
        let shiftWordCount = (amount + UInt.bitWidth - 1) / UInt.bitWidth
        let bachShiftBitCount = shiftWordCount * UInt.bitWidth - amount

        lhs.segments.insert(contentsOf: repeatElement(0, count: shiftWordCount), at: 0)

        lhs >>= bachShiftBitCount
    }

    static func >>= <RHS>(lhs: inout BigInt, rhs: RHS) where RHS : BinaryInteger {
        let amount = Int(rhs)
        assert(amount >= 0, "Shifting right by a negative amount is not allowed")
        let (wordCount, bitCount) = amount.quotientAndRemainder(dividingBy: UInt.bitWidth)
        if wordCount >= lhs.segments.count {
            lhs.segments = []
            return
        }
        lhs.segments.removeFirst(wordCount)

        for i in 0..<lhs.segments.count {
            let this = lhs.segments[i]
            let next = lhs.getSegment(i + 1)
            lhs.segments[i] = this >> bitCount | (next << (UInt.bitWidth - bitCount))
        }
        lhs.segments[lhs.segments.count - 1] |= lhs.exten << (UInt.bitWidth - bitCount)
        lhs.trim()
    }

    var trailingZeroBitCount: Int {
        var result = 0
        if self == 0 { return .max }
        for segment in segments {
            let r = segment.trailingZeroBitCount
            result += r
            if r < UInt.bitWidth {
                return result
            }
        }
        return result
    }
}
