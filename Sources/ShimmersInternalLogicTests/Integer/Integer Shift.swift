//
//  ShimmersInternalLogicTests/Integer/Integer Shift.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct UnsignedShift {
    var result: UInt8

    static func left(_ a: UInt8, _ b: UInt8) -> Self {
        return .init(result: a << b)
    }

    static func right(_ a: UInt8, _ b: UInt8) -> Self {
        return .init(result: a >> b)
    }
}

@HardwareWire
fileprivate struct SignedShift {
    var result: Int8

    static func left(_ a: Int8, _ b: UInt8) -> Self {
        return .init(result: a << b)
    }

    static func right(_ a: Int8, _ b: UInt8) -> Self {
        return .init(result: a >> b)
    }
}

@Suite(
    "Integer Addition & Subtraction",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct IntegerShiftTestSuite {
    @Test func shift_left_unsigned() async throws {
        let network = await dumpSimpleNetwork(of: UnsignedShiftRef.left)

        func sim(_ a: UInt8, _ b: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(a),
                "1": UInt64(b)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        let values: [UInt8] = [1, 3, 4, 7, 13, 19, 123, 255]
        for value in values {
            for i in UInt8(0)...UInt8(10) {
                let truth = value << i
                #expect(sim(value, i) == truth, "\(value) << \(i)")
            }
        }
    }

    @Test func shift_right_unsigned() async throws {
        let network = await dumpSimpleNetwork(of: UnsignedShiftRef.right)

        func sim(_ a: UInt8, _ b: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(a),
                "1": UInt64(b)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        let values: [UInt8] = [1, 3, 68, 76, 148, 180, 123, 255]
        for value in values {
            for i in UInt8(0)...UInt8(10) {
                let truth = value >> i
                #expect(sim(value, i) == truth, "\(value) >> \(i)")
            }
        }
    }

    @Test func shift_left_signed() async throws {
        let network = await dumpSimpleNetwork(of: SignedShiftRef.left)

        func sim(_ a: Int8, _ b: UInt8) -> Int8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(UInt8(bitPattern: a)),
                "1": UInt64(b)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return Int8(truncatingIfNeeded: outputs["result"]!)
        }

        let values: [Int8] = [1, 3, -4, 7, -13, 19, 123]
        for value in values {
            for i in UInt8(0)...UInt8(10) {
                let truth = value << i
                #expect(sim(value, i) == truth, "\(value) << \(i)")
            }
        }
    }

    @Test func shift_right_signed() async throws {
        let network = await dumpSimpleNetwork(of: SignedShiftRef.right)

        func sim(_ a: Int8, _ b: UInt8) -> Int8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(UInt8(bitPattern: a)),
                "1": UInt64(b)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return Int8(truncatingIfNeeded: outputs["result"]!)
        }

        let values: [Int8] = [1, -3, 76, -99, -123, 123, 127, -128]
        for value in values {
            for i in UInt8(0)...UInt8(10) {
                let truth = value >> i
                #expect(sim(value, i) == truth, "\(value) >> \(i)")
            }
        }
    }
}
