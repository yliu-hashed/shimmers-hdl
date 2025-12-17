//
//  ShimmersInternalLogicTests/Construction/Con Switch Unbind Enum.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate enum PayloadEnum4 {
    case a
    case b(UInt8)
    case c(x:UInt8,UInt16)
    case d(UInt8,UInt16,y:UInt8)

    case placeholder_1
    case placeholder_2
    case placeholder_3
    case placeholder_4
    case placeholder_5
}

@HardwareWire
fileprivate struct SwitchEnum4Cases {
    var result: UInt16

    static func unbind_all(_ value: PayloadEnum4) -> Self {
        var result: UInt16
        switch value {
        case .a:
            result = 234
        case .b(let x):
            result = UInt16(x) + 1
        case .c(let x, let y):
            result = UInt16(x) + y + 2
        case .d(let x, let y, y: let z):
            result = UInt16(x) + y + UInt16(z) + 3
        default:
            result = 0
        }
        return .init(result: result)
    }

    static func unbind_value(_ value: PayloadEnum4) -> Self {
        var result: UInt16
        switch value {
        case .a:
            result = 234
        case .b(0x12):
            result = 123
        case .b(0x34):
            result = 345
        case .c(x: 0x12, 0x23):
            result = 1234
        case .d(0x45, 0x56, y: 0x67):
            result = 4567
        default:
            result = 0
        }
        return .init(result: result)
    }

    static func unbind_wildcard(_ value: PayloadEnum4) -> Self {
        var result: UInt16
        switch value {
        case .a:
            result = 2
        case .b(0x34):
            result = 34
        case .b(_):
            result = 3
        case .c(0x12,_):
            result = 12
        case .c(_,_):
            result = 4
        case .d(_,_,_):
            result = 5
        default:
            result = 0
        }
        return .init(result: result)
    }

    static func unbind_mixed(_ value: PayloadEnum4) -> Self {
        var result: UInt16
        switch value {
        case .b(let x), .c(x: let x, 0x1234), .d(_, 0x5678, y: let x), .d(let x, _, y: 0x23):
            result = UInt16(x)
        default:
            result = 0
        }
        return .init(result: result)
    }
}

@Suite(
    "Construction - Switch Statement Enum Unbind",
    .tags(
        .ShimmersInternalTests_Logic.MacroExpansion.codeblock_switch,
        .ShimmersInternalTests_Logic.MacroExpansion.wire_enum,
    )
)
struct ConstructionSwitchEnumUnbindTestSuite {
    @Test func unbind_all() async {
        let network = await dumpSimpleNetwork(of: SwitchEnum4CasesRef.unbind_all)

        func sim(_ raw: UInt64) -> UInt16 {
            let inputs: [String: UInt64] = [
                "0": raw,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt16(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0x00_0000_00_0) == 234)

        #expect(sim(0x00_0000_00_1) == 0x0001)
        #expect(sim(0x00_0000_12_1) == 0x0013)

        #expect(sim(0x00_0000_00_2) == 0x0002)
        #expect(sim(0x00_1111_22_2) == 0x1135)
        #expect(sim(0x00_3456_78_2) == 0x34D0)

        #expect(sim(0x00_0000_00_3) == 0x0003)
        #expect(sim(0x11_2222_33_3) == 0x2269)
        #expect(sim(0x98_7654_32_3) == 0x7721)

        #expect(sim(0x00_0000_00_4) == 0)
        #expect(sim(0x00_0000_00_5) == 0)
    }

    @Test func unbind_value() async {
        let network = await dumpSimpleNetwork(of: SwitchEnum4CasesRef.unbind_value)

        func sim(_ raw: UInt64) -> UInt16 {
            let inputs: [String: UInt64] = [
                "0": raw,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt16(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0x00_0000_00_0) == 234)

        #expect(sim(0x00_0000_00_1) == 0)
        #expect(sim(0x00_0000_11_1) == 0)
        #expect(sim(0x00_0000_56_1) == 0)
        #expect(sim(0x00_0000_12_1) == 123)
        #expect(sim(0x00_0000_34_1) == 345)

        #expect(sim(0x00_0000_00_2) == 0)
        #expect(sim(0x00_1010_10_2) == 0)
        #expect(sim(0x00_0000_12_2) == 0)
        #expect(sim(0x00_0023_00_2) == 0)
        #expect(sim(0x00_0023_12_2) == 1234)

        #expect(sim(0x00_0000_00_3) == 0)
        #expect(sim(0x11_2222_33_3) == 0)
        #expect(sim(0x67_1111_11_3) == 0)
        #expect(sim(0x22_0056_22_3) == 0)
        #expect(sim(0x33_3333_45_3) == 0)
        #expect(sim(0x67_0056_45_3) == 4567)

        #expect(sim(0x00_0000_00_4) == 0)
        #expect(sim(0x00_0000_00_5) == 0)
    }

    @Test func unbind_wildcard() async {
        let network = await dumpSimpleNetwork(of: SwitchEnum4CasesRef.unbind_wildcard)

        func sim(_ raw: UInt64) -> UInt16 {
            let inputs: [String: UInt64] = [
                "0": raw,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt16(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0x00_0000_00_0) == 2)

        #expect(sim(0x00_0000_00_1) == 3)
        #expect(sim(0x00_0000_12_1) == 3)
        #expect(sim(0x00_0000_34_1) == 34)

        #expect(sim(0x00_0000_00_2) == 4)
        #expect(sim(0x00_1010_10_2) == 4)
        #expect(sim(0x00_0023_00_2) == 4)
        #expect(sim(0x00_0000_12_2) == 12)
        #expect(sim(0x00_0023_12_2) == 12)

        #expect(sim(0x00_0000_00_3) == 5)
        #expect(sim(0x11_2222_33_3) == 5)
        #expect(sim(0x67_1111_11_3) == 5)

        #expect(sim(0x00_0000_00_4) == 0)
        #expect(sim(0x00_0000_00_5) == 0)
    }

    @Test func unbind_mixed() async {
        let network = await dumpSimpleNetwork(of: SwitchEnum4CasesRef.unbind_mixed)

        func sim(_ raw: UInt64) -> UInt16 {
            let inputs: [String: UInt64] = [
                "0": raw,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt16(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0x00_0000_00_0) == 0)

        #expect(sim(0x00_0000_00_1) == 0x00)
        #expect(sim(0x00_0000_11_1) == 0x11)
        #expect(sim(0x00_0000_34_1) == 0x34)

        #expect(sim(0x00_0000_00_2) == 0)
        #expect(sim(0x00_1010_10_2) == 0)
        #expect(sim(0x00_1234_12_2) == 0x12)
        #expect(sim(0x00_1234_34_2) == 0x34)
        #expect(sim(0x00_1234_AB_2) == 0xAB)

        #expect(sim(0x00_0000_00_3) == 0)
        #expect(sim(0x11_2222_33_3) == 0)
        #expect(sim(0x67_1111_11_3) == 0)

        #expect(sim(0x12_5678_00_3) == 0x12)
        #expect(sim(0x34_5678_23_3) == 0x34)
        #expect(sim(0x23_5678_45_3) == 0x23)

        #expect(sim(0x23_1234_00_3) == 0x00)
        #expect(sim(0x23_2345_23_3) == 0x23)
        #expect(sim(0x23_3456_45_3) == 0x45)

        #expect(sim(0x00_0000_00_4) == 0)
        #expect(sim(0x00_0000_00_5) == 0)
    }
}
