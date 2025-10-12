//
//  ShimmersInternalLogicTests/Construction/Con If Basic Variable.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct IfBasicVariable {
    var result: UInt8

    static func work1(value: UInt8, decider: UInt8) -> Self {
        var value = value
        if decider > 7 {
            value = 123
        }
        return .init(result: value)
    }

    static func work2(value: UInt8, decider: UInt8) -> Self {
        var value = value
        if decider > 6 {
            if decider < 20 {
                value = 222
            }
            value &+= 3
        }
        return .init(result: value)
    }

    static func work3(value: UInt8, decider: UInt8) -> Self {
        var value = value
        if decider > 3 {
            if decider < 10 {
                value = 111
            } else {
                value &+= 3
            }
        } else {
            value &-= 3
        }
        return .init(result: value)
    }
}

@Suite(
    "Construction - Basic If with Variable",
    .tags(
        .ShimmersInternalTests_Logic.MacroExpansion.codeblock_if,
    )
)
struct ConstructionIfVariableTestSuite {
    @Test func basic() async throws {
        let network = await dumpSimpleNetwork(of: IfBasicVariableRef.work1)

        func sim(_ value: UInt8, _ decider: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(value),
                "1": UInt64(decider)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(99, 0) ==  99)
        #expect(sim(88, 1) ==  88)
        #expect(sim(77, 4) ==  77)
        #expect(sim(66, 7) ==  66)
        #expect(sim(55, 8) == 123)
        #expect(sim(44, 9) == 123)
        #expect(sim(33,13) == 123)
        #expect(sim(22,34) == 123)
        #expect(sim(11,90) == 123)
    }

    @Test func double() async throws {
        let network = await dumpSimpleNetwork(of: IfBasicVariableRef.work2)

        func sim(_ value: UInt8, _ decider: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(value),
                "1": UInt64(decider)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(99, 0) ==  99)
        #expect(sim(88, 1) ==  88)
        #expect(sim(77, 4) ==  77)
        #expect(sim(66, 7) == 225)
        #expect(sim(55, 8) == 225)
        #expect(sim(44, 9) == 225)
        #expect(sim(33,13) == 225)
        #expect(sim(22,21) ==  25)
        #expect(sim(11,40) ==  14)
    }

    @Test func double_else() async throws {
        let network = await dumpSimpleNetwork(of: IfBasicVariableRef.work3)

        func sim(_ value: UInt8, _ decider: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(value),
                "1": UInt64(decider)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(99, 0) ==  96)
        #expect(sim(88, 1) ==  85)
        #expect(sim(77, 3) ==  74)
        #expect(sim(66, 4) == 111)
        #expect(sim(55, 5) == 111)
        #expect(sim(44, 6) == 111)
        #expect(sim(33, 9) == 111)
        #expect(sim(22,10) ==  25)
        #expect(sim(11,11) ==  14)
    }
}
