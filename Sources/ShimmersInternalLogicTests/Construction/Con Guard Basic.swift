//
//  ShimmersInternalLogicTests/Construction/Con Guard Basic.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct GuardBasic {
    var a: Bool
    var b: Bool
    var c: Bool
    var d: Bool

    static func work_one_guard(x: Bool) -> GuardBasic {
        var a: Bool = false
        var b: Bool = false
        var c: Bool = false
        a = true
        guard x else {
            b = true
            return GuardBasic(a: a, b: b, c: c, d: true)
        }
        c = true
        return GuardBasic(a: a, b: b, c: c, d: false)
    }

    static func work_two_guard(x: Bool, y: Bool) -> GuardBasic {
        var a: Bool = false
        var b: Bool = false
        var c: Bool = false
        var d: Bool = false
        guard x else {
            b = true
            return GuardBasic(a: a, b: b, c: c, d: d)
        }
        a = true
        guard y else {
            d = true
            return GuardBasic(a: a, b: b, c: c, d: d)
        }
        c = true
        return GuardBasic(a: a, b: b, c: c, d: d)
    }
}

@Suite(
    "Construction - Basic Guard Statement",
    .tags(
        .ShimmersInternalTests_Logic.MacroExpansion.codeblock_guard,
    )
)
struct ConstructionGuardControlTestSuite {
    @Test func one_guard() async {
        let network = await dumpSimpleNetwork(of: GuardBasicRef.work_one_guard)

        func sim(_ x: UInt64) -> (a: UInt64, b: UInt64, c: UInt64, d: UInt64) {
            let inputs: [String: UInt64] = [
                "0": x,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (
                outputs["a"]!,
                outputs["b"]!,
                outputs["c"]!,
                outputs["d"]!
            )
        }

        #expect(sim(0) == (1, 1, 0, 1))
        #expect(sim(1) == (1, 0, 1, 0))
    }

    @Test func two_guard() async {
        let network = await dumpSimpleNetwork(of: GuardBasicRef.work_two_guard)

        func sim(_ x: UInt64, _ y: UInt64) -> (a: UInt64, b: UInt64, c: UInt64, d: UInt64) {
            let inputs: [String: UInt64] = [
                "0": x, "1": y
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (
                outputs["a"]!,
                outputs["b"]!,
                outputs["c"]!,
                outputs["d"]!
            )
        }

        #expect(sim(0, 0) == (0, 1, 0, 0))
        #expect(sim(0, 1) == (0, 1, 0, 0))
        #expect(sim(1, 0) == (1, 0, 0, 1))
        #expect(sim(1, 1) == (1, 0, 1, 0))
    }
}
