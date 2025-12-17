//
//  ShimmersInternalLogicTests/Optional/Optional.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct OptionalRepresentation {
    var result: Optional<UInt8>

    static func basic(value: UInt8) -> Self {
        var result: Optional<UInt8>
        if value > 123 {
            result = nil
        } else {
            result = .some(value)
        }
        return .init(result: result)
    }
}

@Suite(
    "Optional Tests",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct OptionalTestSuite {
    @Test func optional_representation() async {
        let network = await dumpSimpleNetwork(of: OptionalRepresentationRef.basic)

        func sim(_ a: UInt8) -> (value: UInt8, valid: Bool) {
            let inputs: [String: UInt64] = [
                "0": UInt64(a)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (
                value: UInt8(truncatingIfNeeded: outputs["result_value"]!),
                valid: outputs["result_valid"] != 0
            )
        }

        #expect(sim(  0) == (  0, true ))
        #expect(sim( 33) == ( 33, true ))
        #expect(sim( 55) == ( 55, true ))
        #expect(sim(123) == (123, true ))
        #expect(sim(124) == (  0, false))
        #expect(sim(234) == (  0, false))
        #expect(sim(255) == (  0, false))
    }
}
