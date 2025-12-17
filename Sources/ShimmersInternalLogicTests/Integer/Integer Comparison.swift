//
//  ShimmersInternalLogicTests/Integer/Integer Comparison.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct Comparison {
    var result: Bool

    static func signedLesser(_ a: Int8, _ b: Int8) -> Self {
        return .init(result: a < b)
    }

    static func unsignedLesser(_ a: UInt8, _ b: UInt8) -> Self {
        return .init(result: a < b)
    }
}

@Suite(
    "Integer Comparison",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct IntegerComparisonTestSuite {
    @Test func multiplication_unsigned() async {
        let network = await dumpSimpleNetwork(of: ComparisonRef.unsignedLesser)

        func sim(_ a: UInt8, _ b: UInt8) -> Bool {
            let inputs: [String: UInt64] = [
                "0": UInt64(a),
                "1": UInt64(b)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return outputs["result"] != 0
        }

        let values: [UInt8] = [0, 1, 2, 3, 4, 5, 6, 13, 17, 32, 64, 127, 123, 128, 255]
        for a in values {
            for b in values {
                let answer = a < b
                #expect(sim(a, b) == answer, "\(a) < \(b)")
            }
        }
    }

    @Test func multiplication_signed() async {
        let network = await dumpSimpleNetwork(of: ComparisonRef.signedLesser)

        func sim(_ a: Int8, _ b: Int8) -> Bool {
            let inputs: [String: UInt64] = [
                "0": UInt64(UInt8(bitPattern: a)),
                "1": UInt64(UInt8(bitPattern: b))
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return outputs["result"] != 0
        }

        let values: [Int8] = [0, 1, -1, 2, -3, -4, 5, 6, -13, 17, -32, 64, -127, 123, 127, -128]
        for a in values {
            for b in values {
                let answer = a < b
                #expect(sim(a, b) == answer, "\(a) < \(b)")
            }
        }
    }
}
