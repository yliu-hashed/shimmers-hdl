//
//  ShimmersInternalRuntimeTests/BigInt/BigInt - Shift.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "BigInt Shift",
    .tags(
        .ShimmersInternalTests_Runtime.Support.bigInteger,
    )
)
struct BigIntShiftTestSuite {
    @Test func bigInt_shift_left_small() {
        let values: [BigInt] = [0x1234, 0x4321, -0x1234, -0x4321]
        let truths: [   Int] = [0x1234, 0x4321, -0x1234, -0x4321]

        let count = values.count

        for i in 0..<count {
            for j in 0..<10 {
                let product = values[i] << j
                let truth   = truths[i] << j
                #expect(product == truth, "\(truths[i]) << \(j)")
            }
        }
    }

    @Test func bigInt_shift_right_small() {
        let values: [BigInt] = [0x1234, 0x4321, -0x1234, -0x4321]
        let truths: [   Int] = [0x1234, 0x4321, -0x1234, -0x4321]

        let count = values.count

        for i in 0..<count {
            for j in 0..<10 {
                let product = values[i] >> j
                let truth   = truths[i] >> j
                #expect(product == truth, "\(truths[i]) >> \(j)")
            }
        }
    }

    @Test func bigInt_shift_left_large1() {
        let value: BigInt = 0x12344321_23455432_34566543_45677654
        let product = value << 8
        #expect(product.exten == 0)
        #expect(product.segments.count == 3)
        #expect(product.segments[0] == 0x56654345_67765400)
        #expect(product.segments[1] == 0x34432123_45543234)
        #expect(product.segments[2] == 0x12)
    }

    @Test func bigInt_shift_left_large2() {
        let value: BigInt = 0x12344321_23455432_34566543_45677654
        let product = value << 136
        #expect(product.exten == 0)
        #expect(product.segments.count == 5)
        #expect(product.segments[0] == 0)
        #expect(product.segments[1] == 0)
        #expect(product.segments[2] == 0x56654345_67765400)
        #expect(product.segments[3] == 0x34432123_45543234)
        #expect(product.segments[4] == 0x12)
    }

    @Test func bigInt_shift_right_large1() {
        let value: BigInt = 0x12344321_23455432_34566543_45677654
        let product = value >> 16
        #expect(product.exten == 0)
        #expect(product.segments.count == 2)
        #expect(product.segments[0] == 0x54323456_65434567)
        #expect(product.segments[1] == 0x1234_43212345)
    }

    @Test func bigInt_shift_right_large2() {
        let value: BigInt = 0x12344321_23455432_34566543_45677654
        let product = value >> 88
        #expect(product.exten == 0)
        #expect(product.segments.count == 1)
        #expect(product.segments[0] == 0x1234432123)
    }
}
