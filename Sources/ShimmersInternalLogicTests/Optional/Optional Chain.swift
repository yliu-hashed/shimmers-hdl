//
//  ShimmersInternalLogicTests/Optional/Optional Chain.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct Payload {
    var value: UInt8

    var math: UInt8 {
        return value &+ 1
    }
}

@HardwareWire
fileprivate struct Wrapper1 {
    var value: Optional<Payload>
}

@HardwareWire
fileprivate struct Wrapper2 {
    var value: Optional<Wrapper1>
}

@HardwareWire
fileprivate struct OptionalChainResult {
    var result: Optional<UInt8>

    static func chain1(value: Optional<Payload>) -> Self {
        return Self(result: value?.math)
    }

    static func chain2(value: Optional<Wrapper1>) -> Self {
        return Self(result: value?.value?.math)
    }

    static func chain3(value: Optional<Wrapper2>) -> Self {
        return Self(result: value?.value?.value?.math)
    }
}

@Suite(
    "Optional Chain Tests",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct OptionalChainTestSuite {
    @Test func optional_chain_1() async {
        let network = await dumpSimpleNetwork(of: OptionalChainResultRef.chain1)

        func sim(_ value: UInt8, _ valid: Bool) -> (value: UInt8, valid: Bool) {
            let code = UInt64(value) << 1 | UInt64(valid ? 1 : 0)
            let inputs: [String: UInt64] = [
                "0": code
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (
                value: UInt8(truncatingIfNeeded: outputs["result_value"]!),
                valid: outputs["result_valid"] != 0
            )
        }

        #expect(sim(  0, true) == (  1, true))
        #expect(sim( 10, true) == ( 11, true))
        #expect(sim(123, true) == (124, true))
        #expect(sim(255, true) == (  0, true))

        #expect(sim(  0, false).valid == false)
        #expect(sim( 10, false).valid == false)
        #expect(sim(123, false).valid == false)
        #expect(sim(255, false).valid == false)
    }

    @Test func optional_chain_2() async {
        let network = await dumpSimpleNetwork(of: OptionalChainResultRef.chain2)

        func sim(_ value: UInt8, _ valid1: Bool, _ valid2: Bool) -> (value: UInt8, valid: Bool) {
            let code = UInt64(value) << 2 | UInt64(valid1 ? 1 : 0) << 1 | UInt64(valid2 ? 1 : 0)
            let inputs: [String: UInt64] = [
                "0": code
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (
                value: UInt8(truncatingIfNeeded: outputs["result_value"]!),
                valid: outputs["result_valid"] != 0
            )
        }

        #expect(sim(  0, true, true) == (  1, true))
        #expect(sim( 10, true, true) == ( 11, true))
        #expect(sim(123, true, true) == (124, true))
        #expect(sim(255, true, true) == (  0, true))

        #expect(sim(  0, false, true).valid == false)
        #expect(sim( 10, false, true).valid == false)
        #expect(sim(123, false, true).valid == false)
        #expect(sim(255, false, true).valid == false)

        #expect(sim(  0, true, false).valid == false)
        #expect(sim( 10, true, false).valid == false)
        #expect(sim(123, true, false).valid == false)
        #expect(sim(255, true, false).valid == false)

        #expect(sim(  0, false, false).valid == false)
        #expect(sim( 10, false, false).valid == false)
        #expect(sim(123, false, false).valid == false)
        #expect(sim(255, false, false).valid == false)
    }

    @Test func optional_chain_3() async {
        let network = await dumpSimpleNetwork(of: OptionalChainResultRef.chain3)

        func sim(_ value: UInt8, _ valid1: Bool, _ valid2: Bool, _ valid3: Bool) -> (value: UInt8, valid: Bool) {
            let code = UInt64(value) << 3 | UInt64(valid1 ? 1 : 0) << 2 | UInt64(valid2 ? 1 : 0) << 1 | UInt64(valid3 ? 1 : 0)
            let inputs: [String: UInt64] = [
                "0": code
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (
                value: UInt8(truncatingIfNeeded: outputs["result_value"]!),
                valid: outputs["result_valid"] != 0
            )
        }

        #expect(sim(  0, true, true, true) == (  1, true))
        #expect(sim( 10, true, true, true) == ( 11, true))
        #expect(sim(123, true, true, true) == (124, true))
        #expect(sim(255, true, true, true) == (  0, true))

        #expect(sim(1, false, false, false).valid == false)
        #expect(sim(1, false, false,  true).valid == false)
        #expect(sim(1, false, true,   true).valid == false)
    }
}
