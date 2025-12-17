//
//  ShimmersInternalRuntimeTests/UIntN & IntN/UIntN - Bitwise.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "UIntN Bitwise Operations",
    .tags(
        .ShimmersInternalTests_Runtime.StandardLibrary.integers,
    )
)
struct UIntNBitwiseOperationsTestSuite {
    let vals: [UIntN<8>] = [0, 1, 2, 3, 12, 16, 17, 29, 123, 127, 128, 234, 255]
    let refs: [UInt8   ] = [0, 1, 2, 3, 12, 16, 17, 29, 123, 127, 128, 234, 255]
    let count = 13

    @Test func uIntN_shift_left() async {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i] << j
                let truth  = refs[i] << j
                let name: Comment = "\(refs[i]) << \(refs[j])"
                #expect(result == truth, name)
            }
        }
    }

    @Test func uIntN_shift_right() async {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i] >> j
                let truth  = refs[i] >> j
                let name: Comment = "\(refs[i]) >> \(refs[j])"
                #expect(result == truth, name)
            }
        }
    }

    @Test func uIntN_leading_zeros() async {
        for i in 0..<count {
            let result = vals[i].leadingZeroBitCount
            let truth  = refs[i].leadingZeroBitCount
            let name: Comment = "\(refs[i])"
            #expect(result == truth, name)
        }
    }

    @Test func uIntN_trailing_zeros() async {
        for i in 0..<count {
            let result = vals[i].trailingZeroBitCount
            let truth  = refs[i].trailingZeroBitCount
            let name: Comment = "\(refs[i])"
            #expect(result == truth, name)
        }
    }

    @Test func uIntN_popcount() async {
        for i in 0..<count {
            let result = vals[i].nonzeroBitCount
            let truth  = refs[i].nonzeroBitCount
            let name: Comment = "\(refs[i])"
            #expect(result == truth, name)
        }
    }

    @Test func uIntN_and() async {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i] & vals[i]
                let truth  = refs[i] & refs[i]
                let name: Comment = "\(refs[i]) & \(refs[j])"
                #expect(result == truth, name)
            }
        }
    }

    @Test func uIntN_or() async {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i] | vals[i]
                let truth  = refs[i] | refs[i]
                let name: Comment = "\(refs[i]) | \(refs[j])"
                #expect(result == truth, name)
            }
        }
    }

    @Test func uIntN_xor() async {
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
