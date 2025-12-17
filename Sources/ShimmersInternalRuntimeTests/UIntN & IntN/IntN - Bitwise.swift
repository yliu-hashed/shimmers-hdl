//
//  ShimmersInternalRuntimeTests/UIntN & IntN/IntN - Bitwise.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "IntN Bitwise Operations",
    .tags(
        .ShimmersInternalTests_Runtime.StandardLibrary.integers,
    )
)
struct IntNBitwiseOperationsTestSuite {
    let vals: [IntN<8>] = [0, 1, -1, 2, -3, 12, 16, -17, 29, -123, 127, -127, -128]
    let refs: [Int8   ] = [0, 1, -1, 2, -3, 12, 16, -17, 29, -123, 127, -127, -128]
    let count = 13

    @Test func intN_shift_left() async {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i] << j
                let truth  = refs[i] << j
                let name: Comment = "\(refs[i]) << \(refs[j])"
                #expect(result == truth, name)
            }
        }
    }

    @Test func intN_shift_right() async {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i] >> j
                let truth  = refs[i] >> j
                let name: Comment = "\(refs[i]) >> \(refs[j])"
                #expect(result == truth, name)
            }
        }
    }

    @Test func intN_leading_zeros() async {
        for i in 0..<count {
            let result = vals[i].leadingZeroBitCount
            let truth  = refs[i].leadingZeroBitCount
            let name: Comment = "\(refs[i])"
            #expect(result == truth, name)
        }
    }

    @Test func intN_trailing_zeros() async {
        for i in 0..<count {
            let result = vals[i].trailingZeroBitCount
            let truth  = refs[i].trailingZeroBitCount
            let name: Comment = "\(refs[i])"
            #expect(result == truth, name)
        }
    }

    @Test func intN_popcount() async {
        for i in 0..<count {
            let result = vals[i].nonzeroBitCount
            let truth  = refs[i].nonzeroBitCount
            let name: Comment = "\(refs[i])"
            #expect(result == truth, name)
        }
    }

    @Test func intN_and() async {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i] & vals[i]
                let truth  = refs[i] & refs[i]
                let name: Comment = "\(refs[i]) & \(refs[j])"
                #expect(result == truth, name)
            }
        }
    }

    @Test func intN_or() async {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i] | vals[i]
                let truth  = refs[i] | refs[i]
                let name: Comment = "\(refs[i]) | \(refs[j])"
                #expect(result == truth, name)
            }
        }
    }

    @Test func intN_xor() async {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i] ^ vals[i]
                let truth  = refs[i] ^ refs[i]
                let name: Comment = "\(refs[i]) ^ \(refs[j])"
                #expect(result == truth, name)
            }
        }
    }
}
