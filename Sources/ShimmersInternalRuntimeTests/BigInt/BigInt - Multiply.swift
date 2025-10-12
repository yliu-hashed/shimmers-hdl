//
//  ShimmersInternalRuntimeTests/BigInt/BigInt - Multiply.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "BigInt Multiply",
    .tags(
        .ShimmersInternalTests_Runtime.Support.bigInteger,
    )
)
struct BigIntMultiplyTestSuite {
    @Test func bigInt_multiply_small() {
        let values: [BigInt] = [0x1234, 0x4321, -0x1234, -0x4321]
        let truths: [   Int] = [0x1234, 0x4321, -0x1234, -0x4321]

        let count = values.count

        for i in 0..<count {
            for j in 0..<count {
                let product = values[i] * values[j]
                let truth   = truths[i] * truths[j]
                #expect(product == truth, "\(truths[i]) * \(truths[j])")
            }
        }
    }

    @Test func bigInt_multiply_large1() {
        let value0: BigInt = 0x12344321_23455432_34566543_45677654
        let value1: BigInt = 0x100
        let product = value0 * value1
        #expect(product.exten == 0)
        #expect(product.segments.count == 3)
        #expect(product.segments[0] == 0x56654345_67765400)
        #expect(product.segments[1] == 0x34432123_45543234)
        #expect(product.segments[2] == 0x12)
    }

    @Test func bigInt_multiply_large2() {
        let value0: BigInt = 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF
        let value1: BigInt = 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF
        let product = value0 * value1
        #expect(product.exten == 0)
        #expect(product.segments.count == 4)
        #expect(product.segments[0] == 0x1)
        #expect(product.segments[1] == 0x0)
        #expect(product.segments[2] == 0xFFFFFFFF_FFFFFFFE)
        #expect(product.segments[3] == 0xFFFFFFFF_FFFFFFFF)
        #expect(product == value1 * value0)
    }

    @Test func bigInt_multiply_negative_swap() {
        let values: [BigInt] = [
            0, 10, 123,
            0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF,
            0x12344321_23455432_34566543_45677654,
            0x10001000_01000000_10000000_01000000,
        ]

        for x in values {
            for y in values {
                let product = x * y
                #expect(-product == -y *  x)
                #expect(-product ==  y * -x)
                #expect( product == -y * -x)
            }
        }
    }
}
