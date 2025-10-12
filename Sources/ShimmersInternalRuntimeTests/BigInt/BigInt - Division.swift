//
//  ShimmersInternalRuntimeTests/BigInt/BigInt - Division.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "BigInt Division",
    .tags(
        .ShimmersInternalTests_Runtime.Support.bigInteger,
    )
)
struct BigIntDivisionTestSuite {
    @Test func bigInt_division_small() {
        let values: [BigInt] = [0x1234, 0x4321, 0x37867564_12345678, 0x123412341234, -0x1234, -0x4321]
        let truths: [   Int] = [0x1234, 0x4321, 0x37867564_12345678, 0x123412341234, -0x1234, -0x4321]

        let count = values.count

        for i in 0..<count {
            for j in 0..<count {
                let product = values[i] / values[j]
                let truth   = truths[i] / truths[j]
                #expect(product == truth, "\(truths[i]) / \(truths[j])")
            }
        }
    }

    @Test func bigInt_division_large1() {
        let value0: BigInt = 0xFFFFFFFF_FFFFFFFF_FFFFFFFF
        let value1: BigInt = 0xFFFFFFFF
        let product = value0 / value1
        #expect(product.exten == 0)
        #expect(product.segments.count == 2)
        #expect(product.segments[0] == 0x1_00000001)
        #expect(product.segments[1] == 1)
    }

    @Test func bigInt_division_large2() {
        let value0: BigInt = 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF
        let value1: BigInt = 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF
        let product = value0 / value1
        #expect(product.exten == 0)
        #expect(product.segments.count == 3)
        #expect(product.segments[0] == 0x1)
        #expect(product.segments[1] == 0)
        #expect(product.segments[2] == 0x1)
    }
}
