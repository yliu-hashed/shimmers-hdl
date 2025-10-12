//
//  ShimmersInternalLogicTests/Construction/Con If Return Variable.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct IfReturnVariable {
    var result: UInt8

    static func work1(decider: UInt8) -> Self {
        if decider > 2 {
            return .init(result: 222)
        }
        return .init(result: 111)
    }

    static func work2(decider: UInt8) -> Self {
        var value: UInt8 = 111
        if decider > 3 {
            value = 222
            if decider < 7 {
                return .init(result: value)
            }
            value = 123
        }
        return .init(result: value)
    }

    static func work3(decider: UInt8) -> Self {
        var value: UInt8 = 111
        if decider > 2 {
            value = 222
            if decider < 4 {
                return .init(result: value)
            }
            value = 123
            if decider > 7 {
                return .init(result: value)
            }
            value = 101
        }
        return .init(result: value)
    }
}

@Suite(
    "Construction - Return with Variable",
    .tags(
        .ShimmersInternalTests_Logic.MacroExpansion.codeblock_if,
    )
)
struct ConstructionReturnVariableTestSuite {
    @Test func simple_plain() async throws {
        let network = await dumpSimpleNetwork(of: IfReturnVariableRef.work1)

        func sim(_ decider: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(decider)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0) == 111)
        #expect(sim(1) == 111)
        #expect(sim(2) == 111)
        #expect(sim(3) == 222)
        #expect(sim(4) == 222)
        #expect(sim(5) == 222)
        #expect(sim(6) == 222)
    }

    @Test func simple_valued() async throws {
        let network = await dumpSimpleNetwork(of: IfReturnVariableRef.work2)

        func sim(_ decider: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(decider)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0) == 111)
        #expect(sim(1) == 111)
        #expect(sim(2) == 111)
        #expect(sim(3) == 111)
        #expect(sim(4) == 222)
        #expect(sim(5) == 222)
        #expect(sim(6) == 222)
        #expect(sim(7) == 123)
        #expect(sim(8) == 123)
        #expect(sim(9) == 123)
    }

    @Test func double_valued() async throws {
        let network = await dumpSimpleNetwork(of: IfReturnVariableRef.work3)

        func sim(_ decider: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(decider)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0) == 111)
        #expect(sim(1) == 111)
        #expect(sim(2) == 111)
        #expect(sim(3) == 222)
        #expect(sim(4) == 101)
        #expect(sim(5) == 101)
        #expect(sim(6) == 101)
        #expect(sim(7) == 101)
        #expect(sim(8) == 123)
        #expect(sim(9) == 123)
    }
}
