//
//  ShimmersInternalLogicTests/Integer/Integer Bitwise Ops.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@HardwareWire
fileprivate struct Bitwise {
    var result: UInt8

    static func and(_ a: UInt8, _ b: UInt8) -> Self {
        return .init(result: a & b)
    }

    static func or(_ a: UInt8, _ b: UInt8) -> Self {
        return .init(result: a | b)
    }

    static func xor(_ a: UInt8, _ b: UInt8) -> Self {
        return .init(result: a ^ b)
    }
}

@Suite(
    "Bitwise Operations",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct BitwiseOperationsTestSuite {
    @Test func basic_and() async {
        let network = await dumpSimpleNetwork(of: BitwiseRef.and)

        func sim(_ a: UInt8, _ b: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(a),
                "1": UInt64(b)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0b10101101, 0b01001010) == 0b00001000)
        #expect(sim(0b01010000, 0b10101111) == 0b00000000)
        #expect(sim(0b11001100, 0b01010101) == 0b01000100)
    }

    @Test func basic_or() async {
        let network = await dumpSimpleNetwork(of: BitwiseRef.or)

        func sim(_ a: UInt8, _ b: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(a),
                "1": UInt64(b)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0b10101101, 0b01001010) == 0b11101111)
        #expect(sim(0b01010000, 0b10101111) == 0b11111111)
        #expect(sim(0b11001100, 0b01010101) == 0b11011101)
    }

    @Test func basic_xor() async {
        let network = await dumpSimpleNetwork(of: BitwiseRef.xor)

        func sim(_ a: UInt8, _ b: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(a),
                "1": UInt64(b)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0b10101101, 0b01001010) == 0b11100111)
        #expect(sim(0b01010000, 0b10101111) == 0b11111111)
        #expect(sim(0b11001100, 0b01010101) == 0b10011001)
    }
}
