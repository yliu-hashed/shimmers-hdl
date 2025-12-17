//
//  ShimmersInternalLogicTests/Construction/Con If Basic.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct IfBasic {
    var a: Bool
    var b: Bool
    var c: Bool
    var d: Bool

    static func work_one_branch(x: Bool) -> IfBasic {
        var a: Bool = false
        var b: Bool = false
        var c: Bool = false
        a = true
        if x {
            b = true
        }
        c = true
        return IfBasic(a: a, b: b, c: c, d: false)
    }

    static func work_one_branch_else(x: Bool) -> IfBasic {
        var a: Bool = false
        var b: Bool = false
        var c: Bool = false
        var d: Bool = false
        a = true
        if x {
            b = true
        } else {
            d = true
        }
        c = true
        return IfBasic(a: a, b: b, c: c, d: d)
    }

    static func work_one_branch_double_cond(x: Bool, y: Bool) -> IfBasic {
        var a: Bool = false
        var b: Bool = false
        var c: Bool = false
        var d: Bool = false
        a = true
        if x, y {
            b = true
        } else {
            d = true
        }
        c = true
        return IfBasic(a: a, b: b, c: c, d: d)
    }

    static func work_two_branch(x: Bool, y: Bool) -> IfBasic {
        var a: Bool = false
        var b: Bool = false
        var c: Bool = false
        var d: Bool = false
        a = true
        if x {
            if y {
                b = true
            }
            d = true
        }
        c = true
        return IfBasic(a: a, b: b, c: c, d: d)
    }
}

@Suite(
    "Construction - Basic If Statement",
    .tags(
        .ShimmersInternalTests_Logic.MacroExpansion.codeblock_if,
    )
)
struct ConstructionIfControlTestSuite {
    @Test func one_branch() async {
        let network = await dumpSimpleNetwork(of: IfBasicRef.work_one_branch)

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

        #expect(sim(0) == (1, 0, 1, 0))
        #expect(sim(1) == (1, 1, 1, 0))
    }

    @Test func one_branch_else() async {
        let network = await dumpSimpleNetwork(of: IfBasicRef.work_one_branch_else)

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

        #expect(sim(0) == (1, 0, 1, 1))
        #expect(sim(1) == (1, 1, 1, 0))
    }

    @Test func one_branch_double() async {
        let network = await dumpSimpleNetwork(of: IfBasicRef.work_one_branch_double_cond)

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

        #expect(sim(0, 0) == (1, 0, 1, 1))
        #expect(sim(0, 1) == (1, 0, 1, 1))
        #expect(sim(1, 0) == (1, 0, 1, 1))
        #expect(sim(1, 1) == (1, 1, 1, 0))
    }

    @Test func two_branch() async {
        let network = await dumpSimpleNetwork(of: IfBasicRef.work_two_branch)

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

        #expect(sim(0, 0) == (1, 0, 1, 0))
        #expect(sim(0, 1) == (1, 0, 1, 0))
        #expect(sim(1, 0) == (1, 0, 1, 1))
        #expect(sim(1, 1) == (1, 1, 1, 1))
    }
}
