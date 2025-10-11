//
//  Shimmers/Runtime Support/BigInt/BigInt - Math Add & Sub.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension BigInt {
    static func + (lhs: Self, rhs: Self) -> Self {
        let segmentCount = Swift.max(lhs.segments.count, rhs.segments.count)

        var exten = lhs.exten &+ rhs.exten

        var buffers: [UInt] = []
        buffers.reserveCapacity(segmentCount)
        var overflow: UInt = 0
        for i in 0..<segmentCount {
            let l = lhs.getSegment(i)
            let r = rhs.getSegment(i)
            let (partial1, overflow1) = l.addingReportingOverflow(r)
            let (partial2, overflow2) = partial1.addingReportingOverflow(overflow)
            overflow = overflow1 || overflow2 ? 1 : 0
            buffers.append(partial2)
        }
        exten &+= overflow
        if exten != 0 || exten != ~0 {
            buffers.append(exten)
            let isNegative = exten > (1 << (UInt.bitWidth - 1))
            exten = isNegative ? ~0 : 0
        }
        return BigInt(exten: exten, segments: buffers)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        let segmentCount = Swift.max(lhs.segments.count, rhs.segments.count)

        var exten = lhs.exten &+ ~rhs.exten

        var buffers: [UInt] = []
        buffers.reserveCapacity(segmentCount)
        var overflow: UInt = 1
        for i in 0..<segmentCount {
            let l = lhs.getSegment(i)
            let r = ~rhs.getSegment(i)
            let (partial1, overflow1) = l.addingReportingOverflow(r)
            let (partial2, overflow2) = partial1.addingReportingOverflow(overflow)
            overflow = overflow1 || overflow2 ? 1 : 0
            buffers.append(partial2)
        }
        exten &+= overflow
        if exten != 0 || exten != ~0 {
            buffers.append(exten)
            let isNegative = exten > (1 << (UInt.bitWidth - 1))
            exten = isNegative ? ~0 : 0
        }
        return BigInt(exten: exten, segments: buffers)
    }

    var magnitude: BigInt {
        return exten == 0 ? self : -self
    }
}
