//
//  ShimmersInternalLogicTests/Construction/Con Switch Basic.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct SwitchBasic {
    var result: UInt8

    static func switch_value(_ x: UInt8) -> Self {
        var value: UInt8
        switch x {
        case 0:
            value = 3
        case 1:
            value = 7
        case 2:
            value = 2
        case 3, 5:
            value = 4
        case 4, 7:
            value = 5
        default:
            value = 8
        }
        return .init(result: value)
    }

    static func switch_return(_ x: UInt8) -> Self {
        var value: UInt8
        switch x {
        case 0:
            value = 3
        case 1, 4:
            value = 7
            if x == 4 {
                return .init(result: 9)
            }
            value = 6
        case 2:
            value = 2
        case 3:
            value = 4
        default:
            value = 8
        }
        return .init(result: value)
    }

    static func switch_break(_ x: UInt8) -> Self {
        var value: UInt8
        switch x {
        case 0:
            value = 3
        case 1, 4:
            value = 7
            if x == 4 { break }
            value = 6
        case 2:
            value = 2
        case 3:
            value = 4
        default:
            value = 8
        }
        return .init(result: value)
    }
}

@Suite(
    "Construction - Basic Switch Statement",
    .tags(
        .ShimmersInternalTests_Logic.MacroExpansion.codeblock_switch,
    )
)
struct ConstructionSwitchControlTestSuite {
    @Test func switch_value() async throws {
        let network = await dumpSimpleNetwork(of: SwitchBasicRef.switch_value)

        func sim(_ x: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(x),
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0) == 3)
        #expect(sim(1) == 7)
        #expect(sim(2) == 2)
        #expect(sim(3) == 4)
        #expect(sim(4) == 5)
        #expect(sim(5) == 4)
        #expect(sim(6) == 8)
        #expect(sim(7) == 5)
        #expect(sim(8) == 8)
        #expect(sim(9) == 8)
        #expect(sim(123) == 8)
        #expect(sim(234) == 8)
    }

    @Test func switch_return() async throws {
        let network = await dumpSimpleNetwork(of: SwitchBasicRef.switch_return)

        func sim(_ x: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(x),
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0) == 3)
        #expect(sim(1) == 6)
        #expect(sim(2) == 2)
        #expect(sim(3) == 4)
        #expect(sim(4) == 9)
        #expect(sim(123) == 8)
        #expect(sim(234) == 8)
    }

    @Test func switch_break() async throws {
        let network = await dumpSimpleNetwork(of: SwitchBasicRef.switch_break)

        func sim(_ x: UInt8) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(x),
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0) == 3)
        #expect(sim(1) == 6)
        #expect(sim(2) == 2)
        #expect(sim(3) == 4)
        #expect(sim(4) == 7)
        #expect(sim(123) == 8)
        #expect(sim(234) == 8)
    }
}
