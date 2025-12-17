//
//  ShimmersInternalLogicTests/Range/Range Iterate.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct RangeIterateBasic {
    var result: InlineArray<16, Bool>

    static func range(buffer: InlineArray<16, Bool>) -> Self {
        var result = buffer
        let range: Range<Int> = 7..<13
        for i in range {
            result[i] = !result[i]
        }
        return .init(result: result)
    }
}

@HardwareWire
fileprivate struct RangeIterateSeeded {
    var result: Int8

    static func seeded(seed: Int8) -> Self {
        var result: Int8 = 0
        let range: Range<Int8> = 7..<13
        for i in range {
            result &+= i &* seed
        }
        return .init(result: result)
    }
}

@Suite(
    "Range Iterate",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct RangeIterateTestSuite {
    @Test func basic() async {
        let network = await dumpSimpleNetwork(of: RangeIterateBasicRef.range)
        func sim(_ buffer: UInt16) -> UInt16 {
            let inputs: [String: UInt64] = [
                "0": UInt64(buffer)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            var buffer: UInt16 = 0
            for i in 0..<16 {
                buffer |= (outputs["result_\(i)"] != 0) ? 1 << i : 0
            }
            return buffer
        }
        #expect(sim(0b11111111_11111111) == 0b11100000_01111111)
        #expect(sim(0b01010101_01010101) == 0b01001010_11010101)
    }

    @Test func seeded() async {
        let network = await dumpSimpleNetwork(of: RangeIterateSeededRef.seeded)
        func sim(_ seed: Int8) -> Int8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(seed)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return Int8(truncatingIfNeeded: outputs["result"]!)
        }
        for seed: Int8 in [1, 2, 34, 123] {
            let truth = RangeIterateSeeded.seeded(seed: seed).result
            #expect(sim(seed) == truth)
        }
    }
}
