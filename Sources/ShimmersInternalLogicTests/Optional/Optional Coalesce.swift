//
//  ShimmersInternalLogicTests/Optional/Optional Coalesce.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct OptionalCoalesceConcreteResult {
    var result: UInt8

    static func coalesce1(value1: Optional<UInt8>, value2: UInt8) -> Self {
        let r = value1 ?? value2
        return Self(result: r)
    }

    static func coalesce2(value1: Optional<UInt8>, value2: Optional<UInt8>, value3: UInt8) -> Self {
        let r = value1 ?? value2 ?? value3
        return Self(result: r)
    }
}

@HardwareWire
fileprivate struct OptionalCoalesceOptionalResult {
    var result: Optional<UInt8>

    static func coalesce1(value1: Optional<UInt8>, value2: Optional<UInt8>) -> Self {
        let r = value1 ?? value2
        return Self(result: r)
    }
}

@Suite(
    "Optional Coalesce Tests",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct OptionalCoalesceTests {
    @Test func optional_coalesce_concrete_1() async {
        let network = await dumpSimpleNetwork(of: OptionalCoalesceConcreteResultRef.coalesce1)

        func sim(_ value1: UInt8, _ value1Valid: Bool, _ value2: UInt8) -> UInt8 {
            let v1 = UInt64(value1) << 1 | UInt64(value1Valid ? 1 : 0)
            let v2 = UInt64(value2)
            let inputs: [String: UInt64] = [
                "0": v1,
                "1": v2
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(  0, true, 234) ==   0)
        #expect(sim( 10, true, 234) ==  10)
        #expect(sim(123, true, 234) == 123)
        #expect(sim(255, true, 234) == 255)

        #expect(sim(  0, false, 255) == 255)
        #expect(sim( 10, false, 123) == 123)
        #expect(sim(123, false,  10) ==  10)
        #expect(sim(255, false,   0) ==   0)
    }

    @Test func optional_coalesce_concrete_2() async {
        let network = await dumpSimpleNetwork(of: OptionalCoalesceConcreteResultRef.coalesce2)

        func sim(_ value1: UInt8, _ value1Valid: Bool, _ value2: UInt8, _ value2Valid: Bool, _ value3: UInt8) -> UInt8 {
            let v1 = UInt64(value1) << 1 | UInt64(value1Valid ? 1 : 0)
            let v2 = UInt64(value2) << 1 | UInt64(value2Valid ? 1 : 0)
            let v3 = UInt64(value3)
            let inputs: [String: UInt64] = [
                "0": v1,
                "1": v2,
                "2": v3
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(  0, true,  12,  true, 255) ==   0)
        #expect(sim( 10, true,  87, false, 123) ==  10)
        #expect(sim(123, true, 133,  true,  10) == 123)
        #expect(sim(255, true, 129, false,   0) == 255)

        #expect(sim(  0, false,  12, true, 255) ==  12)
        #expect(sim( 10, false,  87, true, 123) ==  87)
        #expect(sim(123, false, 133, true,  10) == 133)
        #expect(sim(255, false, 129, true,   0) == 129)

        #expect(sim(  0, false,  12, false, 255) == 255)
        #expect(sim( 10, false,  87, false, 123) == 123)
        #expect(sim(123, false, 133, false,  10) ==  10)
        #expect(sim(255, false, 129, false,   0) ==   0)
    }

    @Test func optional_coalesce_optional_1() async {
        let network = await dumpSimpleNetwork(of: OptionalCoalesceOptionalResultRef.coalesce1)

        func sim(_ value1: UInt8, _ value1Valid: Bool, _ value2: UInt8, _ value2Valid: Bool) -> (value: UInt8, valid: Bool) {
            let v1 = UInt64(value1) << 1 | UInt64(value1Valid ? 1 : 0)
            let v2 = UInt64(value2) << 1 | UInt64(value2Valid ? 1 : 0)
            let inputs: [String: UInt64] = [
                "0": v1,
                "1": v2
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (
                value: UInt8(truncatingIfNeeded: outputs["result_value"]!),
                valid: outputs["result_valid"] != 0
            )
        }

        #expect(sim(  0, true, 255,  true) == (  0, true))
        #expect(sim( 10, true, 123, false) == ( 10, true))
        #expect(sim(123, true,  10,  true) == (123, true))
        #expect(sim(255, true,   0, false) == (255, true))

        #expect(sim(  0, false, 255, true) == (255, true))
        #expect(sim( 10, false, 123, true) == (123, true))
        #expect(sim(123, false,  10, true) == ( 10, true))
        #expect(sim(255, false,   0, true) == (  0, true))

        #expect(sim(  0, false, 255, false).valid == false)
        #expect(sim( 10, false, 123, false).valid == false)
        #expect(sim(123, false,  10, false).valid == false)
        #expect(sim(255, false,   0, false).valid == false)
    }
}
