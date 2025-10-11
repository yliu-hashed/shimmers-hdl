//
//  Shimmers/Runtime Support/BigInt/BigInt.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

internal struct BigInt: BinaryInteger, SignedInteger {
    var bitWidth: Int {
        var width = segments.count * UInt.bitWidth
        if let lastSegment = segments.last {
            let segment = (exten == 0) ? lastSegment : ~lastSegment
            width -= segment.leadingZeroBitCount
        }
        return width
    }

    typealias Magnitude = BigInt
    typealias Stride = Int

    var exten: UInt
    var segments: [UInt]

    init(exten: UInt, segments: consuming [UInt]) {
        self.exten = exten
        self.segments = segments
        trim()
    }

    @inlinable
    internal func getSegment(_ index: Int) -> UInt {
        if index >= segments.count { return exten }
        return segments[index]
    }

    @inlinable
    internal func getBit(at index: Int) -> Bool {
        let segIndex = index / UInt.bitWidth
        let bitIndex = index % UInt.bitWidth
        let segment = getSegment(segIndex)
        return segment & (1 << bitIndex) != 0
    }

    @inlinable
    internal mutating func trim() {
        while segments.last == exten {
            segments.removeLast()
        }
    }

    @inlinable
    internal mutating func expand(to size: Int) {
        while segments.count < size {
            segments.append(exten)
        }
    }

    @inlinable
    internal mutating func truncatingSigned(to bitWidth: Int) {
        guard bitWidth <= segments.count * UInt.bitWidth + 1 else { return }

        let segmentCount = (bitWidth + UInt.bitWidth - 1) / UInt.bitWidth
        let bitsLeft = bitWidth % UInt.bitWidth
        if segmentCount < segments.count {
            segments.removeLast(segments.count - segmentCount)
        }
        if segmentCount > segments.count {
            segments.append(contentsOf: repeatElement(exten, count: segmentCount - segments.count))
        }
        if bitsLeft != 0 {
            segments[segmentCount - 1] &= (1 << bitsLeft) - 1
        }
        let isNegative = getBit(at: bitWidth - 1)
        exten = isNegative ? .max : 0
        if isNegative {
            segments[segmentCount - 1] |= (.max << bitsLeft)
        }
        trim()
    }

    @inlinable
    internal mutating func truncatingUnsigned(to bitWidth: Int) {
        assert(bitWidth > 0)
        let segmentCount = (bitWidth + UInt.bitWidth - 1) / UInt.bitWidth
        let bitsLeft = bitWidth % UInt.bitWidth
        if segmentCount < segments.count {
            segments.removeLast(segments.count - segmentCount)
        }
        if segmentCount > segments.count {
            segments.append(contentsOf: repeatElement(exten, count: segmentCount - segments.count))
        }
        exten = 0
        if bitsLeft != 0 {
            segments[segmentCount - 1] &= (1 << bitsLeft) - 1
        }
        trim()
    }
}
