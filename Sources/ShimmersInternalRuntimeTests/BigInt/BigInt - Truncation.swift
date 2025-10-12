//
//  ShimmersInternalRuntimeTests/BigInt/BigInt - Truncation.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "BigInt - Truncation",
    .tags(
        .ShimmersInternalTests_Runtime.Support.bigInteger,
    )
)
struct BigIntTruncationTestSuite {
    @Test func bitInt_truncation_unsigned_positive() {
        let value = BigInt(exten: 0, segments: [
            0x12345677_12345677, 0x22345677_22345677
        ])

        func get(_ count: Int) -> BigInt {
            var result = value
            result.truncatingUnsigned(to: count)
            return result
        }

        let truncate_16 = BigInt(exten: 0, segments: [
            0x5677,
        ])
        #expect(get(16) == truncate_16)

        let truncate_64 = BigInt(exten: 0, segments: [
            0x12345677_12345677,
        ])
        #expect(get(64) == truncate_64)

        let truncate_65 = BigInt(exten: 0, segments: [
            0x12345677_12345677, 1
        ])
        #expect(get(65) == truncate_65)

        #expect(get(128) == value)
        #expect(get(129) == value)
    }

    @Test func bitInt_truncation_unsigned_negative() {
        let value = BigInt(exten: .max, segments: [
            0x12345677_12345677, 0x22345677_22345677
        ])

        func get(_ count: Int) -> BigInt {
            var result = value
            result.truncatingUnsigned(to: count)
            return result
        }

        let truncate_16 = BigInt(exten: 0, segments: [
            0x5677,
        ])
        #expect(get(16) == truncate_16)

        let truncate_64 = BigInt(exten: 0, segments: [
            0x12345677_12345677,
        ])
        #expect(get(64) == truncate_64)

        let truncate_65 = BigInt(exten: 0, segments: [
            0x12345677_12345677, 1
        ])
        #expect(get(65) == truncate_65)

        let truncate_128 = BigInt(exten: 0, segments: [
            0x12345677_12345677, 0x22345677_22345677
        ])
        #expect(get(128) == truncate_128)

        let truncate_129 = BigInt(exten: 0, segments: [
            0x12345677_12345677, 0x22345677_22345677, 1
        ])
        #expect(get(129) == truncate_129)
    }

    @Test func bitInt_truncation_signed_positive() {
        let value = BigInt(exten: 0, segments: [
            0x12345677_12345677, 0x22345677_22345677
        ])

        func get(_ count: Int) -> BigInt {
            var result = value
            result.truncatingSigned(to: count)
            return result
        }

        let truncate_16 = BigInt(exten: 0, segments: [
            0x5677,
        ])
        #expect(get(16) == truncate_16)

        let truncate_19 = BigInt(exten: .max, segments: [
            0xFFFFFFFF_FFFC5677,
        ])
        #expect(get(19) == truncate_19)

        let truncate_64 = BigInt(exten: 0, segments: [
            0x12345677_12345677,
        ])
        #expect(get(64) == truncate_64)

        let truncate_65 = BigInt(exten: .max, segments: [
            0x12345677_12345677
        ])
        #expect(get(65) == truncate_65)

        #expect(get(128) == value)
        #expect(get(129) == value)
    }

    @Test func bitInt_truncation_signed_negative() {
        let value = BigInt(exten: .max, segments: [
            0x12345677_12345677, 0x22345677_22345677
        ])

        func get(_ count: Int) -> BigInt {
            var result = value
            result.truncatingSigned(to: count)
            return result
        }

        let truncate_16 = BigInt(exten: 0, segments: [
            0x5677,
        ])
        #expect(get(16) == truncate_16)

        let truncate_19 = BigInt(exten: .max, segments: [
            0xFFFFFFFF_FFFC5677,
        ])
        #expect(get(19) == truncate_19)

        let truncate_64 = BigInt(exten: 0, segments: [
            0x12345677_12345677,
        ])
        #expect(get(64) == truncate_64)

        let truncate_65 = BigInt(exten: .max, segments: [
            0x12345677_12345677
        ])
        #expect(get(65) == truncate_65)

        let truncate_128 = BigInt(exten: 0, segments: [
            0x12345677_12345677, 0x22345677_22345677
        ])
        #expect(get(128) == truncate_128)

        let truncate_129 = BigInt(exten: .max, segments: [
            0x12345677_12345677, 0x22345677_22345677
        ])
        #expect(get(129) == truncate_129)
    }
}
