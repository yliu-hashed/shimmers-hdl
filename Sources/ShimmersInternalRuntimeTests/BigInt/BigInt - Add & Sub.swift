//
//  ShimmersInternalRuntimeTests/BigInt/BigInt - Add & Sub.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "BigInt Addition & Subtraction",
    .tags(
        .ShimmersInternalTests_Runtime.Support.bigInteger,
    )
)
struct BigIntAddiitonSubtractionTestSuite {
    @Test func bigInt_addition_simple() {
        let values: [BigInt] = [0x1234, 0x4321, -0x1234, -0x4321]
        let truths: [   Int] = [0x1234, 0x4321, -0x1234, -0x4321]

        for i in 0..<4 {
            for j in 0..<4 {
                let product = values[i] + values[j]
                let truth   = truths[i] + truths[j]
                #expect(product == truth, "\(truths[i]) + \(truths[j])")
            }
        }
    }

    @Test func bigInt_subtraction_simple() {
        let values: [BigInt] = [0x1234, 0x4321, -0x1234, -0x4321]
        let truths: [   Int] = [0x1234, 0x4321, -0x1234, -0x4321]

        for i in 0..<4 {
            for j in 0..<4 {
                let product = values[i] - values[j]
                let truth   = truths[i] - truths[j]
                #expect(product == truth, "\(truths[i]) - \(truths[j])")
            }
        }
    }

    @Test func bigInt_addition_long() {
        let value0: BigInt = 0x12345678_23456789_98765432_87654321
        let value1: BigInt = 0x11111111_22222222_33333333_44444444
        let sum = value0 + value1
        #expect(sum.exten == 0)
        #expect(sum.segments.count == 2)
        #expect(sum.segments[0] == 0xCBA98765_CBA98765)
        #expect(sum.segments[1] == 0x23456789_456789AB)
    }

    @Test func bigInt_subtraction_long() {
        let value0: BigInt = 0x12345678_23456789_98765432_87654321
        let value1: BigInt = 0x11111111_22222222_22222222_11111111
        let sum = value0 - value1
        #expect(sum.exten == 0)
        #expect(sum.segments.count == 2)
        #expect(sum.segments[0] == 0x76543210_76543210)
        #expect(sum.segments[1] == 0x01234567_01234567)
    }

    @Test func bigInt_addition_carry1() {
        let value0: BigInt = 0xFFFFFFFF_FFFFFFFF
        let value1: BigInt = 1
        let sum = value0 + value1
        #expect(sum.exten == 0)
        #expect(sum.segments.count == 2)
        #expect(sum.segments[0] == 0)
        #expect(sum.segments[1] == 1)
    }

    @Test func bigInt_addition_carry2() {
        let value0: BigInt = 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF
        let value1: BigInt = 1
        let sum = value0 + value1
        #expect(sum.exten == 0)
        #expect(sum.segments.count == 3)
        #expect(sum.segments[0] == 0)
        #expect(sum.segments[1] == 0)
        #expect(sum.segments[2] == 1)
    }

    @Test func bigInt_subtraction_carry1() {
        let value0: BigInt = 0x1_FFFFFFFF_FFFFFFFE
        let value1: BigInt =   0xFFFFFFFF_FFFFFFFF
        let sum = value0 - value1
        #expect(sum.exten == 0)
        #expect(sum.segments.count == 1)
        #expect(sum.segments[0] == 0xFFFFFFFF_FFFFFFFF)
    }

    @Test func bigInt_subtraction_carry2() {
        let value0: BigInt = 0x1_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE
        let value1: BigInt =   0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF
        let sum = value0 - value1
        #expect(sum.exten == 0)
        #expect(sum.segments.count == 2)
        #expect(sum.segments[0] == 0xFFFFFFFF_FFFFFFFF)
        #expect(sum.segments[1] == 0xFFFFFFFF_FFFFFFFF)
    }
}
