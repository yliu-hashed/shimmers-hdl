//
//  Shimmers/Runtime Support/BigInt/BigInt - Math Mul & Div.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension BigInt {
    static func * (lhs: Self, rhs: Self) -> Self {
        // slow path
        let lhsMag = lhs.magnitude.segments
        let rhsMag = rhs.magnitude.segments

        let bufferCount = lhsMag.count + rhsMag.count + 1

        var buffers = [UInt](repeating: 0, count: bufferCount)
        for (i, l) in lhsMag.enumerated() {
            for (j, r) in rhsMag.enumerated() {
                let index = i + j
                let (hi, lo) = l.multipliedFullWidth(by: r)
                let (partial1, overflow1) = buffers[index].addingReportingOverflow(lo)
                buffers[index] = partial1
                let (partial2, overflow2) = buffers[index + 1].addingReportingOverflow(hi + (overflow1 ? 1 : 0))
                buffers[index + 1] = partial2
                var carry = overflow2
                var k = index + 2
                while carry {
                    let (partial, overflow) = buffers[k].addingReportingOverflow(1)
                    buffers[k] = partial
                    carry = overflow
                    k += 1
                }
            }
        }

        let result = BigInt(exten: 0, segments: buffers)

        let newExten = lhs.exten ^ rhs.exten
        if newExten != 0 {
            return -result
        } else {
            return result
        }
    }

    private mutating func shiftLeft(in value: Bool) {
        var carry: UInt = value ? 1 : 0
        for i in 0..<segments.count {
            let c = segments[i] >> (UInt.bitWidth - 1)
            segments[i] = (segments[i] << 1) | carry
            carry = c
        }
        if carry != exten & 1 {
            segments.append(exten ^ 1)
        }
    }

    private static func divisionAlgorithm(_ n: Self, _ d: Self) -> (quotient: Self, remainder: Self) {
        assert(n.exten == 0 && d.exten == 0)
        var i = n.segments.count * UInt.bitWidth
        var q: BigInt = 0
        var r: BigInt = 0
        q.segments = Array(repeating: 0, count: n.segments.count)
        while (i != 0) {
            i -= 1
            r.shiftLeft(in: n.getBit(at: i))
            if r >= d {
                r -= d
                let segIndex = i / UInt.bitWidth;
                let bitIndex = i % UInt.bitWidth;
                q.segments[segIndex] |= 1 << bitIndex
            }
        }
        q.trim()
        r.trim()
        return (q, r)
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        assert(rhs != 0)
        let (q, _) = divisionAlgorithm(lhs.magnitude, rhs.magnitude)
        let negate = lhs.exten != rhs.exten
        return negate ? -q : q
    }

    static func % (lhs: Self, rhs: Self) -> Self {
        assert(rhs != 0)
        let (_, r) = divisionAlgorithm(lhs.magnitude, rhs.magnitude)
        let negate = lhs.exten != 0
        return negate ? -r : r
    }

    static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }

    static func %= (lhs: inout Self, rhs: Self) {
        lhs = lhs % rhs
    }
}
