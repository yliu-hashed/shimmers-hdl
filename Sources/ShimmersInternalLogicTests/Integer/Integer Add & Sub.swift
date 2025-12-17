//
//  ShimmersInternalLogicTests/Integer/Integer Add & Sub.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct UnsignedAdder {
    var result: UInt8
    var overflow: Bool

    static func add(_ a: UInt8, _ b: UInt8) -> Self {
        let (result, overflow) = a.addingReportingOverflow(b)
        return .init(result: result, overflow: overflow)
    }

    static func sub(_ a: UInt8, _ b: UInt8) -> Self {
        let (result, overflow) = a.subtractingReportingOverflow(b)
        return .init(result: result, overflow: overflow)
    }
}

@HardwareWire
fileprivate struct SignedAdder {
    var result: Int8
    var overflow: Bool

    static func add(_ a: Int8, _ b: Int8) -> Self {
        let (result, overflow) = a.addingReportingOverflow(b)
        return .init(result: result, overflow: overflow)
    }

    static func sub(_ a: Int8, _ b: Int8) -> Self {
        let (result, overflow) = a.subtractingReportingOverflow(b)
        return .init(result: result, overflow: overflow)
    }
}

@Suite(
    "Integer Addition & Subtraction",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct IntegerAdditionSubtractionTestSuite {
    @Test func addition_unsigned() async {
        let network = await dumpSimpleNetwork(of: UnsignedAdderRef.add)

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

        let values: [UInt8] = [0, 1, 7, 9, 123, 127, 128, 164, 245, 255]
        for a in values {
            for b in values {
                let (partial, overflow) = a.addingReportingOverflow(b)
                #expect(sim(a, b) == (partial, overflow), "\(a) + \(b)")
            }
        }
    }

    @Test func subtraction_unsigned() async {
        let network = await dumpSimpleNetwork(of: UnsignedAdderRef.sub)

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

        let values: [UInt8] = [0, 1, 7, 9, 123, 127, 128, 164, 245, 255]
        for a in values {
            for b in values {
                let (partial, overflow) = a.subtractingReportingOverflow(b)
                #expect(sim(a, b) == (partial, overflow), "\(a) - \(b)")
            }
        }
    }

    @Test func addition_signed() async {
        let network = await dumpSimpleNetwork(of: SignedAdderRef.add)

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

        let values: [Int8] = [0, 1, -2, 7, 9, 27, 36, -61, 78, 127, -127, -128]
        for a in values {
            for b in values {
                let (partial, overflow) = a.addingReportingOverflow(b)
                #expect(sim(a, b) == (partial, overflow), "\(a) + \(b)")
            }
        }
    }

    @Test func subtraction_signed() async {
        let network = await dumpSimpleNetwork(of: SignedAdderRef.sub)

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

        let values: [Int8] = [0, 1, -2, 7, 9, 27, 36, -61, 78, 127, -127, -128]
        for a in values {
            for b in values {
                let (partial, overflow) = a.subtractingReportingOverflow(b)
                #expect(sim(a, b) == (partial, overflow), "\(a) - \(b)")
            }
        }
    }
}
