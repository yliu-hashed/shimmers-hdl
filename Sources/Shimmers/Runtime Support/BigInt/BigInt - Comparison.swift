//
//  Shimmers/Runtime Support/BigInt/BigInt - Comparison.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension BigInt {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.exten == rhs.exten && lhs.segments == rhs.segments
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.exten != rhs.exten {
            return lhs.exten != 0
        }
        let segmentCount = Swift.max(lhs.segments.count, rhs.segments.count)
        for i in 0..<segmentCount {
            let l = lhs.getSegment(i)
            let r = rhs.getSegment(i)
            if l != r { return l < r }
        }
        return false
    }
}
