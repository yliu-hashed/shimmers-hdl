//
//  ShimmersInternalLogicTests/Range/Range Contain.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct RangeContain {
    var result: Bool

    static func contain(range: Range<Int8>, value: Int8) -> Self {
        return .init(result: range.contains(value))
    }
}

@Suite(
    "Range Contain",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct RangeContainTestSuite {
    @Test func range_contain() async {
        let network = await dumpSimpleNetwork(of: RangeContainRef.contain)
        func sim(_ range: Range<Int8>, _ value: Int8) -> Bool {
            let lower = UInt64(UInt8(bitPattern: range.lowerBound))
            let upper = UInt64(UInt8(bitPattern: range.upperBound))
            let input0 = lower | (upper << 8)
            let inputs: [String: UInt64] = [
                "0": input0,
                "1": UInt64(UInt8(bitPattern: value))
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return outputs["result"] != 0
        }

        let ranges: [Range<Int8>] = [0..<5, 2..<3, 1..<7, 3..<15, 7..<12, 90..<123]
        for range in ranges {
            let minTestValue = range.lowerBound - 3
            let maxTestValue = range.upperBound + 3
            for value in minTestValue..<maxTestValue {
                let truth = range.contains(value)
                #expect(sim(range, value) == truth, "\(range) in \(value)")
            }
        }
    }
}
