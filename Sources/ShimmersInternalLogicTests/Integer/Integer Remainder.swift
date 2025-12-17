//
//  ShimmersInternalLogicTests/Integer/Integer Remainder.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct UnsignedRemainder {
    var result: UInt8
    var overflow: Bool

    static func rem(_ a: UInt8, _ b: UInt8) -> Self {
        let (result, overflow) = a.remainderReportingOverflow(dividingBy: b)
        return .init(result: result, overflow: overflow)
    }
}

@HardwareWire
fileprivate struct SignedRemainder {
    var result: Int8
    var overflow: Bool

    static func rem(_ a: Int8, _ b: Int8) -> Self {
        let (result, overflow) = a.remainderReportingOverflow(dividingBy: b)
        return .init(result: result, overflow: overflow)
    }
}

@Suite(
    "Integer Remainder",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct IntegerRemainderTestSuite {
    @Test func remainder_unsigned() async {
        let network = await dumpSimpleNetwork(of: UnsignedRemainderRef.rem)

        func sim(_ a: UInt8, _ b: UInt8) -> (result: UInt8, overflow: Bool) {
            let inputs: [String: UInt64] = [
                "0": UInt64(a),
                "1": UInt64(b)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (
                result: UInt8(truncatingIfNeeded: outputs["result"]!),
                overflow: outputs["overflow"] != 0
            )
        }

        let values: [UInt8] = [0, 1, 2, 3, 4, 5, 6, 13, 17, 32, 64, 127, 123, 128, 255]
        for a in values {
            for b in values {
                let answer = a.remainderReportingOverflow(dividingBy: b)
                #expect(sim(a, b) == (answer.partialValue, answer.overflow), "\(a) rem \(b)")
            }
        }
    }

    @Test func remainder_signed() async {
        let network = await dumpSimpleNetwork(of: SignedRemainderRef.rem)

        func sim(_ a: Int8, _ b: Int8) -> (result: Int8, overflow: Bool) {
            let inputs: [String: UInt64] = [
                "0": UInt64(UInt8(bitPattern: a)),
                "1": UInt64(UInt8(bitPattern: b))
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (
                result: Int8(truncatingIfNeeded: outputs["result"]!),
                overflow: outputs["overflow"] != 0
            )
        }

        let values: [Int8] = [0, 1, -1, 2, -3, -4, 5, 6, -13, 17, -32, 64, -127, 123, 127, -128]
        for a in values {
            for b in values {
                let answer = a.remainderReportingOverflow(dividingBy: b)
                #expect(sim(a, b) == (answer.partialValue, answer.overflow), "\(a) rem \(b)")
            }
        }
    }
}
