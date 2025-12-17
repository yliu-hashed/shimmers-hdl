//
//  ShimmersInternalLogicTests/Integer/Integer Sign & Mag.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct IntegerSign {
    var result: Int8

    static func signum(_ value: Int8) -> Self {
        return .init(result: value.signum())
    }
}

@HardwareWire
fileprivate struct IntegerMagnitude {
    var result: UInt8

    static func magnitude(_ value: Int8) -> Self {
        return .init(result: value.magnitude)
    }
}

@Suite(
    "Integer Sign & Magnitude",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct IntegerSignAndMagnitudeTestSuite {
    @Test func sign() async {
        let network = await dumpSimpleNetwork(of: IntegerSignRef.signum)

        func sim(_ value: Int8) -> Int8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(UInt8(bitPattern: value))
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return Int8(truncatingIfNeeded: outputs["result"]!)
        }

        let values: [Int8] = [0, 1, -1, 7, -9, 17, 23, -99, 123, -127, -128, 127]
        for value in values {
            let truth = value.signum()
            #expect(sim(value) == truth, "signum of \(value)")
        }
    }

    @Test func magnitude() async {
        let network = await dumpSimpleNetwork(of: IntegerMagnitudeRef.magnitude)

        func sim(_ value: Int8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(UInt8(bitPattern: value))
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        let values: [Int8] = [0, 1, -1, 7, -9, 17, 23, -99, 123, -127, -128, 127]
        for value in values {
            let truth = value.magnitude
            #expect(sim(value) == truth, "magnitude of \(value)")
        }
    }
}
