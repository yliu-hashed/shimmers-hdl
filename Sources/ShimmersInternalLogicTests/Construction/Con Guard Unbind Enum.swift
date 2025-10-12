//
//  ShimmersInternalLogicTests/Construction/Con Guard Unbind Enum.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate enum UnbindEnum4 {
    case a
    case b(UInt8)
    case c(x:UInt8,UInt16)
    case d(UInt8,UInt16,y: UInt8)

    case placeholder_1
    case placeholder_2
    case placeholder_3
    case placeholder_4
    case placeholder_5

    static func unbind_direct(_ value: UnbindEnum4) -> UInt8 {
        guard case .a = value else {
            return 0
        }
        return 123
    }

    static func unbind_identifier(_ value: UnbindEnum4) -> UInt8 {
        guard case .b(let x) = value else {
            return 0
        }
        return x
    }

    static func unbind_wildcard(_ value: UnbindEnum4) -> UInt8 {
        guard case .b(_) = value else {
            return 0
        }
        return 234
    }

    static func unbind_value(_ value: UnbindEnum4) -> UInt8 {
        guard case .b(0x23) = value else {
            return 0
        }
        return 123
    }
}

@Suite(
    "Construction - Enum Unbind with Guard Statements",
    .tags(
        .ShimmersInternalTests_Logic.MacroExpansion.codeblock_guard,
        .ShimmersInternalTests_Logic.MacroExpansion.wire_enum,
    )
)
struct ConstructionGuardEnumUnbindSuite {
    @Test func unbind_direct() async throws {
        let network = await dumpSimpleNetwork(of: UnbindEnum4Ref.unbind_direct)

        func sim(_ raw: UInt64) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": raw,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["value"]!)
        }

        #expect(sim(0x00_0000_00_0) == 123)

        #expect(sim(0x00_0000_00_1) == 0)
        #expect(sim(0x00_0000_12_1) == 0)
        #expect(sim(0x00_3456_78_2) == 0)
        #expect(sim(0x23_4567_89_3) == 0)
        #expect(sim(0x00_0000_00_4) == 0)
        #expect(sim(0x00_0000_00_5) == 0)
    }

    @Test func unbind_identifier() async throws {
        let network = await dumpSimpleNetwork(of: UnbindEnum4Ref.unbind_identifier)

        func sim(_ raw: UInt64) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": raw,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["value"]!)
        }

        #expect(sim(0x00_0000_00_0) == 0)

        #expect(sim(0x00_0000_00_1) == 0)
        #expect(sim(0x00_0000_12_1) == 0x12)
        #expect(sim(0x00_0000_76_1) == 0x76)
        #expect(sim(0x00_0000_AB_1) == 0xAB)

        #expect(sim(0x00_3456_78_2) == 0)
        #expect(sim(0x23_4567_89_3) == 0)
        #expect(sim(0x00_0000_00_4) == 0)
        #expect(sim(0x00_0000_00_5) == 0)
    }

    @Test func unbind_wildcard() async throws {
        let network = await dumpSimpleNetwork(of: UnbindEnum4Ref.unbind_wildcard)

        func sim(_ raw: UInt64) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": raw,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["value"]!)
        }

        #expect(sim(0x00_0000_00_0) == 0)

        #expect(sim(0x00_0000_00_1) == 234)
        #expect(sim(0x00_0000_12_1) == 234)
        #expect(sim(0x00_0000_76_1) == 234)
        #expect(sim(0x00_0000_AB_1) == 234)

        #expect(sim(0x00_3456_78_2) == 0)
        #expect(sim(0x23_4567_89_3) == 0)
        #expect(sim(0x00_0000_00_4) == 0)
        #expect(sim(0x00_0000_00_5) == 0)
    }

    @Test func unbind_value() async throws {
        let network = await dumpSimpleNetwork(of: UnbindEnum4Ref.unbind_value)

        func sim(_ raw: UInt64) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": raw,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["value"]!)
        }

        #expect(sim(0x00_0000_00_0) == 0)

        #expect(sim(0x00_0000_00_1) == 0)
        #expect(sim(0x00_0000_12_1) == 0)
        #expect(sim(0x00_0000_32_1) == 0)
        #expect(sim(0x00_0000_23_1) == 123)
        #expect(sim(0x00_0000_23_1) == 123)

        #expect(sim(0x00_3456_78_2) == 0)
        #expect(sim(0x23_4567_89_3) == 0)
        #expect(sim(0x00_0000_00_4) == 0)
        #expect(sim(0x00_0000_00_5) == 0)
    }
}
