//
//  ShimmersInternalRuntimeTests/BigInt/BigInt - Bitwise.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "BigInt Bitwise Operations",
    .tags(
        .ShimmersInternalTests_Runtime.Support.bigInteger,
    )
)
struct BigIntBitwiseTestSuite {
    @Test func bigInt_and_uniform() {
        let value0: BigInt = 0xFFFF0000_0F0F0F0F_0000FFFF_F0F0F0F0
        let value1: BigInt = 0xFFFFFFFF_F0F0F0F0_0000FFFF_F0F0F0F0
        let result = value0 & value1
        #expect(result.exten == 0)
        #expect(result.segments.count == 2)
        #expect(result.segments[0] == 0x0000FFFF_F0F0F0F0)
        #expect(result.segments[1] == 0xFFFF0000_00000000)
        #expect(result == value1 & value0)
    }

    @Test func bigInt_and_mismatch() {
        let value0: BigInt = 0xFFFF0000_0F0F0F0F_0000FFFF_F0F0F0F0
        let value1: BigInt = 0xFFFFFFFF_FFFFFFFF
        let result = value0 & value1
        #expect(result.exten == 0)
        #expect(result.segments.count == 1)
        #expect(result.segments[0] == 0x0000FFFF_F0F0F0F0)
        #expect(result == value1 & value0)
    }

    @Test func bigInt_and_negative() {
        let value0: BigInt = 0xFFFF0000_0F0F0F0F_0000FFFF_F0F0F0F0
        let value1: BigInt = -1
        let result = value0 & value1
        #expect(result.exten == 0)
        #expect(result.segments.count == 2)
        #expect(result.segments[0] == 0x0000FFFF_F0F0F0F0)
        #expect(result.segments[1] == 0xFFFF0000_0F0F0F0F)
        #expect(result == value1 & value0)
    }

    @Test func bigInt_or_uniform() {
        let value0: BigInt = 0xFFFF0000_0F0F0F0F_0000FFFF_F0F0F0F0
        let value1: BigInt = 0x0000FFFF_F0F0F0F0_0000FFFF_F0F0F0F0
        let result = value0 | value1
        #expect(result.exten == 0)
        #expect(result.segments.count == 2)
        #expect(result.segments[0] == 0x0000FFFF_F0F0F0F0)
        #expect(result.segments[1] == 0xFFFFFFFF_FFFFFFFF)
        #expect(result == value1 | value0)
    }

    @Test func bigInt_or_mismatch() {
        let value0: BigInt = 0xFFFF0000_0F0F0F0F_0000FFFF_F0F0F0F0
        let value1: BigInt = 0xFFFFFFFF_FFFFFFFF
        let result = value0 | value1
        #expect(result.exten == 0)
        #expect(result.segments.count == 2)
        #expect(result.segments[0] == 0xFFFFFFFF_FFFFFFFF)
        #expect(result.segments[1] == 0xFFFF0000_0F0F0F0F)
        #expect(result == value1 | value0)
    }

    @Test func bigInt_or_negative() {
        let value0: BigInt = 0xFFFF0000_0F0F0F0F_0000FFFF_F0F0F0F0
        let value1: BigInt = -1
        let result = value0 | value1
        #expect(result.exten == .max)
        #expect(result.segments.count == 0)
        #expect(result == value1 | value0)
    }

    @Test func bigInt_xor_uniform() {
        let value0: BigInt = 0xFFFF0000_0F0F0F0F_0000FFFF_F0F0F0F0
        let value1: BigInt = 0x0000FFFF_F0F0F0F0_0000FFFF_F0F0F0F0
        let result = value0 ^ value1
        #expect(result.exten == 0)
        #expect(result.segments.count == 2)
        #expect(result.segments[0] == 0)
        #expect(result.segments[1] == 0xFFFFFFFF_FFFFFFFF)
        #expect(result == value1 ^ value0)
    }

    @Test func bigInt_xor_mismatch() {
        let value0: BigInt = 0xFFFF0000_0F0F0F0F_0000FFFF_F0F0F0F0
        let value1: BigInt = 0xFFFFFFFF_FFFFFFFF
        let result = value0 ^ value1
        #expect(result.exten == 0)
        #expect(result.segments.count == 2)
        #expect(result.segments[0] == 0xFFFF0000_0F0F0F0F)
        #expect(result.segments[1] == 0xFFFF0000_0F0F0F0F)
        #expect(result == value1 ^ value0)
    }

    @Test func bigInt_xor_negative() {
        let value0: BigInt = 0xFFFF0000_0F0F0F0F_0000FFFF_F0F0F0F0
        let value1: BigInt = -1
        let result = value0 ^ value1
        #expect(result.exten == .max)
        #expect(result.segments.count == 2)
        #expect(result.segments[0] == 0xFFFF0000_0F0F0F0F)
        #expect(result.segments[1] == 0x0000FFFF_F0F0F0F0)
        #expect(result == value1 ^ value0)
    }

    @Test func bigInt_trailing_zeros() {
        let value0: BigInt = 0xFFFF0000_0F0F0000_FFFF0000_0F0F0F0F
        let value1: BigInt = 0xFFFF0000_0F0F0000_FFFF0000_0F0F0F00
        let value2: BigInt = 0xFFFF0000_0F0F0000_00000000_00000000
        #expect(value0.trailingZeroBitCount == 0)
        #expect(value1.trailingZeroBitCount == 8)
        #expect(value2.trailingZeroBitCount == 80)
    }
}
