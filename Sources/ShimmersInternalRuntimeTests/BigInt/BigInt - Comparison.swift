//
//  ShimmersInternalRuntimeTests/BigInt/BigInt - Comparison.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "BigInt Comparison",
    .tags(
        .ShimmersInternalTests_Runtime.Support.bigInteger,
    )
)
struct BigIntComparisonTestSuite {
    @Test func bigInt_comparison_simple() {
        let values: [BigInt] = [0x1234, 0x4321, -0x1234, -0x4321]
        let truths: [   Int] = [0x1234, 0x4321, -0x1234, -0x4321]

        for i in 0..<4 {
            for j in 0..<4 {
                #expect((values[i] == values[j]) == (truths[i] == truths[j]), "\(truths[i]) == \(truths[j])")
                #expect((values[i] <  values[j]) == (truths[i] <  truths[j]), "\(truths[i]) < \(truths[j])")
            }
        }
    }

    @Test func bigInt_comparison_long1() {
        let values: [BigInt] = [
            0x12345678_12345678_00000000,
            0xEDCBA987_ECA8DB98_00000000,
            -0x12345678_12345678_00000000,
            -0xEDCBA987_ECA8DB98_00000000,
        ]
        let truths: [Int] = [
            0x1234_1234,
            0xEDCB_ECA8,
            -0x1234_1234,
            -0xEDCB_ECA8,
        ]

        for i in 0..<4 {
            for j in 0..<4 {
                #expect((values[i] == values[j]) == (truths[i] == truths[j]), "\(truths[i]) == \(truths[j])")
                #expect((values[i] <  values[j]) == (truths[i] <  truths[j]), "\(truths[i]) < \(truths[j])")
            }
        }
    }

    @Test func bigInt_comparison_long2() {
        let values: [BigInt] = [
            0x12345678_00000000_00000000,
            0x23456789_00000000_00000000,
            -0x12345678_00000000_00000000,
            -0x23456789_00000000_00000000,
        ]
        let truths: [Int] = [
            0x1234,
            0x2345,
            -0x1234,
            -0x2345,
        ]

        for i in 0..<4 {
            for j in 0..<4 {
                #expect((values[i] == values[j]) == (truths[i] == truths[j]), "\(truths[i]) == \(truths[j])")
                #expect((values[i] <  values[j]) == (truths[i] <  truths[j]), "\(truths[i]) < \(truths[j])")
            }
        }
    }
}
