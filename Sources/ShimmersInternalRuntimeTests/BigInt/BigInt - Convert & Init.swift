//
//  ShimmersInternalRuntimeTests/BigInt/BigInt - Convert & Init.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "BigInt Convert & Init",
    .tags(
        .ShimmersInternalTests_Runtime.Support.bigInteger,
    )
)
struct BigIntConvertInitTestSuite {
    @Test func bigInt_literal_small() {
        let value0: BigInt = 0x12345678_90ABCDEF
        #expect(value0.exten == 0)
        #expect(value0.segments.count == 1)
        #expect(value0.segments[0] == 0x12345678_90ABCDEF)

        let value1: BigInt = -0x12345678_90ABCDEF
        #expect(value1.exten == .max)
        #expect(value1.segments.count == 1)
        #expect(value1.segments[0] == 0xEDCBA987_6F543211)
    }

    @Test func bigInt_literal_large() {
        let truth0: StaticBigInt = 0x12345678_90ABCDEF_FEDCBA09_87654321_DEADBEEF_BEEFDEAD
        let value0 = BigInt(integerLiteral: truth0)
        #expect(value0.exten == 0)
        #expect(value0.segments.count == 3)
        #expect(value0.segments[0] == truth0[0])
        #expect(value0.segments[1] == truth0[1])
        #expect(value0.segments[2] == truth0[2])

        let truth1: StaticBigInt = -0x12345678_90ABCDEF_FEDCBA09_87654321_DEADBEEF_BEEFDEAD
        let value1 = BigInt(integerLiteral: truth1)
        #expect(value1.exten == .max)
        #expect(value1.segments.count == 3)
        #expect(value1.segments[0] == truth1[0])
        #expect(value1.segments[1] == truth1[1])
        #expect(value1.segments[2] == truth1[2])
    }

    @Test func bigInt_convert_from() {
        let value0: BigInt = BigInt(0x12345678_90ABCDEF)
        #expect(value0.exten == 0)
        #expect(value0.segments.count == 1)
        #expect(value0.segments[0] == 0x12345678_90ABCDEF)

        let value1: BigInt = BigInt(-0x12345678_90ABCDEF)
        #expect(value1.exten == .max)
        #expect(value1.segments.count == 1)
        #expect(value1.segments[0] == 0xEDCBA987_6F543211)
    }

    @Test func bigInt_convert_to() {
        let value0: BigInt = 0x12345678_90ABCDEF
        #expect(Int(value0) == 0x12345678_90ABCDEF)

        let value1: BigInt = -0x12345678_90ABCDEF
        #expect(Int(value1) == -0x12345678_90ABCDEF)
    }
}
