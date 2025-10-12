//
//  ShimmersInternalLogicTests/Construction/Con If Unbind Enum.swift
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
        if case .a = value {
            return 123
        }
        return 0
    }

    static func unbind_all_1a(_ value: UnbindEnum4) -> UInt8 {
        if case .b(let x) = value {
            return x
        }
        return 0
    }

    static func unbind_all_1b(_ value: UnbindEnum4) -> UInt8 {
        if case let .b(x) = value {
            return x
        }
        return 0
    }

    static func unbind_wildcard_1a(_ value: UnbindEnum4) -> UInt8 {
        if case .b(_) = value {
            return 234
        }
        return 0
    }

    static func unbind_all_3a(_ value: UnbindEnum4) -> UInt16 {
        if case .d(let u, let v, let w) = value {
            return UInt16(u) + v + UInt16(w)
        }
        return 0
    }

    static func unbind_all_3b(_ value: UnbindEnum4) -> UInt16 {
        if case let .d(u, v, w) = value {
            return UInt16(u) + v + UInt16(w)
        }
        return 0
    }

    static func unbind_mixed_3a(_ value: UnbindEnum4) -> UInt16 {
        if case .d(0xAB, let v, 0x23) = value {
            return v
        }
        return 0
    }

    static func unbind_mixed_3b(_ value: UnbindEnum4) -> UInt16 {
        if case let .d(0xAB, v, 0x23) = value {
            return v
        }
        return 0
    }

    static func unbind_wildcard_3a(_ value: UnbindEnum4) -> UInt8 {
        if case .d(0x54, _, let v) = value {
            return v
        }
        return 0
    }

    static func unbind_wildcard_3b(_ value: UnbindEnum4) -> UInt8 {
        if case let .d(0x54, _, v) = value {
            return v
        }
        return 0
    }
}

@Suite(
    "Construction - Enum Unbind with If Statements",
    .tags(
        .ShimmersInternalTests_Logic.MacroExpansion.codeblock_if,
        .ShimmersInternalTests_Logic.MacroExpansion.wire_enum,
    )
)
struct ConstructionIfEnumUnbindSuite {
    @Test func unbind_direct_1() async throws {
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

    @Test(arguments: ["inside", "outside"])
    func unbind_all_1(choice: String) async throws {
        let target = switch choice {
        case "inside":
            UnbindEnum4Ref.unbind_all_1a
        case "outside":
            UnbindEnum4Ref.unbind_all_1b
        default:
            fatalError("Invalid choice \(choice)")
        }

        let network = await dumpSimpleNetwork(of: target)

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

    @Test func unbind_wildcard_1() async throws {
        let network = await dumpSimpleNetwork(of: UnbindEnum4Ref.unbind_wildcard_1a)

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

    @Test(arguments: ["inside", "outside"])
    func unbind_all_3(choice: String) async throws {
        let target = switch choice {
        case "inside":
            UnbindEnum4Ref.unbind_all_3a
        case "outside":
            UnbindEnum4Ref.unbind_all_3b
        default:
            fatalError("Invalid choice \(choice)")
        }

        let network = await dumpSimpleNetwork(of: target)

        func sim(_ raw: UInt64) -> UInt16 {
            let inputs: [String: UInt64] = [
                "0": raw,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt16(truncatingIfNeeded: outputs["value"]!)
        }

        #expect(sim(0x00_0000_00_0) == 0)
        #expect(sim(0x00_0000_AB_1) == 0)
        #expect(sim(0x00_3456_78_2) == 0)

        #expect(sim(0x00_0000_00_3) == 0)
        #expect(sim(0x01_0002_03_3) == 6)
        #expect(sim(0x12_3456_78_3) == 0x34E0)
        #expect(sim(0x98_7654_32_3) == 0x771E)

        #expect(sim(0x00_0000_00_4) == 0)
        #expect(sim(0x00_0000_00_5) == 0)
    }

    @Test(arguments: ["inside", "outside"])
    func unbind_mixed_3(choice: String) async throws {
        let target = switch choice {
        case "inside":
            UnbindEnum4Ref.unbind_mixed_3a
        case "outside":
            UnbindEnum4Ref.unbind_mixed_3b
        default:
            fatalError("Invalid choice \(choice)")
        }

        let network = await dumpSimpleNetwork(of: target)

        func sim(_ raw: UInt64) -> UInt16 {
            let inputs: [String: UInt64] = [
                "0": raw,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt16(truncatingIfNeeded: outputs["value"]!)
        }

        #expect(sim(0x00_0000_00_0) == 0)
        #expect(sim(0x00_0000_AB_1) == 0)
        #expect(sim(0x00_3456_78_2) == 0)

        #expect(sim(0x00_0000_00_3) == 0)
        #expect(sim(0x23_0002_03_3) == 0)
        #expect(sim(0x12_3456_78_3) == 0)
        #expect(sim(0x98_7654_AB_3) == 0)

        #expect(sim(0x23_7654_AB_3) == 0x7654)
        #expect(sim(0x23_1234_AB_3) == 0x1234)

        #expect(sim(0x00_0000_00_4) == 0)
        #expect(sim(0x00_0000_00_5) == 0)
    }

    @Test(arguments: ["inside", "outside"])
    func unbind_wildcard_3(choice: String) async throws {
        let target = switch choice {
        case "inside":
            UnbindEnum4Ref.unbind_wildcard_3a
        case "outside":
            UnbindEnum4Ref.unbind_wildcard_3b
        default:
            fatalError("Invalid choice \(choice)")
        }

        let network = await dumpSimpleNetwork(of: target)

        func sim(_ raw: UInt64) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": raw,
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["value"]!)
        }

        #expect(sim(0x00_0000_00_0) == 0)
        #expect(sim(0x00_0000_AB_1) == 0)
        #expect(sim(0x00_3456_78_2) == 0)

        #expect(sim(0x12_3456_78_3) == 0)
        #expect(sim(0x98_7654_32_3) == 0)

        #expect(sim(0x00_0000_54_3) == 0x00)
        #expect(sim(0x01_0002_54_3) == 0x01)
        #expect(sim(0x12_3456_54_3) == 0x12)
        #expect(sim(0x98_7654_54_3) == 0x98)

        #expect(sim(0x00_0000_00_4) == 0)
        #expect(sim(0x00_0000_00_5) == 0)
    }
}
