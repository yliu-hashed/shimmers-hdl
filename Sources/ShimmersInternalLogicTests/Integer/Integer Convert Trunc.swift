//
//  ShimmersInternalLogicTests/Integer/Integer Convert Trunc.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct IntegerConversionTruncatingToUnsigned {
    var result: UInt8

    static func fromUnsigned(value: UInt16) -> Self {
        return .init(result: UInt8(truncatingIfNeeded: value))
    }

    static func fromSigned(value: Int16) -> Self {
        return .init(result: UInt8(truncatingIfNeeded: value))
    }
}

@HardwareWire
fileprivate struct IntegerConversionTruncatingToSigned {
    var result: Int8

    static func fromUnsigned(value: UInt16) -> Self {
        return .init(result: Int8(truncatingIfNeeded: value))
    }

    static func fromSigned(value: Int16) -> Self {
        return .init(result: Int8(truncatingIfNeeded: value))
    }
}

@Suite(
    "Integer Conversion - Truncating",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct IntegerConversionTruncatingTestSuite {
    @Test func unsigned_from_trunc_unsigned() async throws {
        let network = await dumpSimpleNetwork(of: IntegerConversionTruncatingToSignedRef.fromUnsigned)

        func sim(_ a: UInt16) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(a)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        let values: [UInt16] = [0, 1, 10, 55, 127, 128, 222, 255, 256, 4321, 54321]
        for value in values {
            let truncated = UInt8(truncatingIfNeeded: value)
            #expect(sim(value) == truncated, "truncating \(value)")
        }
    }

    @Test func unsigned_from_trunc_signed() async throws {
        let network = await dumpSimpleNetwork(of: IntegerConversionTruncatingToSignedRef.fromSigned)

        func sim(_ a: Int16) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(UInt16(bitPattern: a))
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        let values: [Int16] = [0, 1, -10, 55, 127, 128, -127, -128, 222, 255, 256, -255, -256, 4321, 12345]
        for value in values {
            let truncated = UInt8(truncatingIfNeeded: value)
            #expect(sim(value) == truncated, "truncating \(value)")
        }
    }

    @Test func signed_from_trunc_unsigned() async throws {
        let network = await dumpSimpleNetwork(of: IntegerConversionTruncatingToSignedRef.fromUnsigned)

        func sim(_ a: UInt16) -> Int8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(a)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return Int8(truncatingIfNeeded: outputs["result"]!)
        }

        let values: [UInt16] = [0, 1, 10, 55, 127, 128, 222, 255, 256, 4321, 54321]
        for value in values {
            let truncated = Int8(truncatingIfNeeded: value)
            #expect(sim(value) == truncated, "truncating \(value)")
        }
    }

    @Test func signed_from_trunc_signed() async throws {
        let network = await dumpSimpleNetwork(of: IntegerConversionTruncatingToSignedRef.fromSigned)

        func sim(_ a: Int16) -> Int8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(UInt16(bitPattern: a))
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return Int8(truncatingIfNeeded: outputs["result"]!)
        }

        let values: [Int16] = [0, 1, -10, 55, 127, 128, -127, -128, 222, 255, 256, -255, -256, 4321, 12345]
        for value in values {
            let truncated = Int8(truncatingIfNeeded: value)
            #expect(sim(value) == truncated, "truncating \(value)")
        }
    }
}
