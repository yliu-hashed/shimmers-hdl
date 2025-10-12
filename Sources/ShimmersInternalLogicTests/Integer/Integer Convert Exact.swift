//
//  ShimmersInternalLogicTests/Integer/Integer Convert Exact.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct IntegerConversionExactlyToUnsigned {
    var result: Optional<UInt8>

    static func fromUnsigned(value: UInt16) -> Self {
        return .init(result: UInt8.exactly(value))
    }

    static func fromSigned(value: Int16) -> Self {
        return .init(result: UInt8.exactly(value))
    }
}

@HardwareWire
fileprivate struct IntegerConversionExactlyToSigned {
    var result: Optional<Int8>

    static func fromUnsigned(value: UInt16) -> Self {
        return .init(result: Int8.exactly(value))
    }

    static func fromSigned(value: Int16) -> Self {
        return .init(result: Int8.exactly(value))
    }
}

@Suite(
    "Integer Conversion - Exactly",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct IntegerConversionExactlyTestSuite {
    @Test func unsigned_from_exactly_unsigned() async throws {
        let network = await dumpSimpleNetwork(of: IntegerConversionExactlyToUnsignedRef.fromUnsigned)

        func sim(_ a: UInt16) -> UInt8? {
            let inputs: [String: UInt64] = [
                "0": UInt64(a)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            let valid = outputs["result_valid"]! != 0
            let value = UInt8(truncatingIfNeeded: outputs["result_value"]!)
            return valid ? value : nil
        }

        let values: [UInt16] = [0, 1, 10, 55, 127, 128, 222, 255, 256, 4321, 54321]
        for value in values {
            let truncated = UInt8.exactly(value)
            #expect(sim(value) == truncated, "exactly \(value)")
        }
    }

    @Test func unsigned_from_exactly_signed() async throws {
        let network = await dumpSimpleNetwork(of: IntegerConversionExactlyToUnsignedRef.fromSigned)

        func sim(_ a: Int16) -> UInt8? {
            let inputs: [String: UInt64] = [
                "0": UInt64(UInt16(bitPattern: a))
            ]
            let outputs = simulate(network: network, inputs: inputs)
            let valid = outputs["result_valid"]! != 0
            let value = UInt8(truncatingIfNeeded: outputs["result_value"]!)
            return valid ? value : nil
        }

        let values: [Int16] = [0, 1, -10, 55, 127, 128, -127, -128, 222, 255, 256, -255, -256, 4321, 12345]
        for value in values {
            let truncated = UInt8.exactly(value)
            #expect(sim(value) == truncated, "exactly \(value)")
        }
    }

    @Test func signed_from_exactly_unsigned() async throws {
        let network = await dumpSimpleNetwork(of: IntegerConversionExactlyToSignedRef.fromUnsigned)

        func sim(_ a: UInt16) -> Int8? {
            let inputs: [String: UInt64] = [
                "0": UInt64(a)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            let valid = outputs["result_valid"]! != 0
            let value = Int8(truncatingIfNeeded: outputs["result_value"]!)
            return valid ? value : nil
        }

        let values: [UInt16] = [0, 1, 10, 55, 127, 128, 222, 255, 256, 4321, 54321]
        for value in values {
            let truncated = Int8.exactly(value)
            #expect(sim(value) == truncated, "exactly \(value)")
        }
    }

    @Test func signed_from_exactly_signed() async throws {
        let network = await dumpSimpleNetwork(of: IntegerConversionExactlyToSignedRef.fromSigned)

        func sim(_ a: Int16) -> Int8? {
            let inputs: [String: UInt64] = [
                "0": UInt64(UInt16(bitPattern: a))
            ]
            let outputs = simulate(network: network, inputs: inputs)
            let valid = outputs["result_valid"]! != 0
            let value = Int8(truncatingIfNeeded: outputs["result_value"]!)
            return valid ? value : nil
        }

        let values: [Int16] = [0, 1, -10, 55, 127, 128, -127, -128, 222, 255, 256, -255, -256, 4321, 12345]
        for value in values {
            let truncated = Int8.exactly(value)
            #expect(sim(value) == truncated, "exactly \(value)")
        }
    }
}
