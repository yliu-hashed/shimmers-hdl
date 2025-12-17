//
//  ShimmersInternalLogicTests/Integer/Integer Bitwise Count.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct BitwiseCount {
    var result: Int

    static func leadingZero(of value: UInt8) -> Self {
        return .init(result: value.leadingZeroBitCount)
    }

    static func trailingZero(of value: UInt8) -> Self {
        return .init(result: value.trailingZeroBitCount)
    }

    static func populationCount(of value: UInt8) -> Self {
        return .init(result: value.nonzeroBitCount)
    }
}

@Suite(
    "Bitwise Counting",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct BitwiseCountingTestSuite {
    @Test func count_leading_zeros() async {
        let network = await dumpSimpleNetwork(of: BitwiseCountRef.leadingZero)

        func sim(_ value: UInt8) -> Int {
            let inputs: [String: UInt64] = [
                "0": UInt64(value)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return Int(outputs["result"]!)
        }

        #expect(sim(0b10101101) == 0)
        #expect(sim(0b01010000) == 1)
        #expect(sim(0b00101001) == 2)
        #expect(sim(0b00011101) == 3)
        #expect(sim(0b00001010) == 4)
        #expect(sim(0b00000101) == 5)
        #expect(sim(0b00000011) == 6)
        #expect(sim(0b00000001) == 7)
        #expect(sim(0b00000000) == 8)
    }

    @Test func count_trailing_zeros() async {
        let network = await dumpSimpleNetwork(of: BitwiseCountRef.trailingZero)

        func sim(_ value: UInt8) -> Int {
            let inputs: [String: UInt64] = [
                "0": UInt64(value)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return Int(outputs["result"]!)
        }

        #expect(sim(0b10111001) == 0)
        #expect(sim(0b01010010) == 1)
        #expect(sim(0b01110100) == 2)
        #expect(sim(0b00101000) == 3)
        #expect(sim(0b01010000) == 4)
        #expect(sim(0b11100000) == 5)
        #expect(sim(0b01000000) == 6)
        #expect(sim(0b10000000) == 7)
        #expect(sim(0b00000000) == 8)
    }

    @Test func count_population() async {
        let network = await dumpSimpleNetwork(of: BitwiseCountRef.populationCount)

        func sim(_ value: UInt8) -> Int {
            let inputs: [String: UInt64] = [
                "0": UInt64(value)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return Int(outputs["result"]!)
        }

        #expect(sim(0b00000000) == 0)
        #expect(sim(0b00100000) == 1)
        #expect(sim(0b00001100) == 2)
        #expect(sim(0b10010010) == 3)
        #expect(sim(0b01011001) == 4)
        #expect(sim(0b10010111) == 5)
        #expect(sim(0b10111110) == 6)
        #expect(sim(0b01111111) == 7)
        #expect(sim(0b11111111) == 8)
    }
}
