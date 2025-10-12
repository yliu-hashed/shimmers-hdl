//
//  ShimmersInternalLogicTests/Enum/Enum Rep Payload.swift
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
    case d(UInt8,UInt16,y: UInt8)
}

@HardwareWire
fileprivate struct PayloadEnum4Cases {
    var result: PayloadEnum4

    static func make_a() -> Self {
        return Self(result: .a)
    }

    static func make_b(_ a: UInt8) -> Self {
        return Self(result: .b(a))
    }

    static func make_c(_ a: UInt8, _ b: UInt16) -> Self {
        return Self(result: .c(x: a, b))
    }

    static func make_d(_ a: UInt8, _ b: UInt16, _ c: UInt8) -> Self {
        return Self(result: .d(a, b, y: c))
    }
}

@Suite(
    "Representation of Enum with Payload",
    .tags(
        .ShimmersInternalTests_Logic.MacroExpansion.wire_enum,
    )
)
struct EnumPayloadTestSuite {
    @Test func case_bitLength() async throws {
        #expect(PayloadEnum4Ref._bitWidth == 34)
    }

    @Test func case_create_simple() async throws {
        let network = await dumpSimpleNetwork(of: PayloadEnum4CasesRef.make_a)

        func sim() -> (kind: UInt64, payload: UInt64) {
            let inputs: [String: UInt64] = [:]
            let outputs = simulate(network: network, inputs: inputs)
            return (outputs["result_kind"]!, outputs["result_payload"]!)
        }

        #expect(sim() == (0, 0x00_0000_00))
    }

    @Test func case_create_long1() async throws {
        let network = await dumpSimpleNetwork(of: PayloadEnum4CasesRef.make_b)

        func sim(_ a: UInt64) -> (kind: UInt64, payload: UInt64) {
            let inputs: [String: UInt64] = [
                "0": a
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (outputs["result_kind"]!, outputs["result_payload"]!)
        }

        #expect(sim(   0) == (1, 0x00_0000_00))
        #expect(sim(0x34) == (1, 0x00_0000_34))
        #expect(sim(0x56) == (1, 0x00_0000_56))
        #expect(sim(0xAB) == (1, 0x00_0000_AB))
        #expect(sim(0xFF) == (1, 0x00_0000_FF))
    }

    @Test func case_create_long2() async throws {
        let network = await dumpSimpleNetwork(of: PayloadEnum4CasesRef.make_c)

        func sim(_ a: UInt64, _ b: UInt64) -> (kind: UInt64, payload: UInt64) {
            let inputs: [String: UInt64] = [
                "0": a, "1": b
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (outputs["result_kind"]!, outputs["result_payload"]!)
        }

        #expect(sim(   0,      0) == (2, 0x00_0000_00))
        #expect(sim(0x34, 0x1234) == (2, 0x00_1234_34))
        #expect(sim(0x56, 0x2345) == (2, 0x00_2345_56))
        #expect(sim(0xAB, 0xCDEF) == (2, 0x00_CDEF_AB))
        #expect(sim(0xFF,      0) == (2, 0x00_0000_FF))
        #expect(sim(   0, 0xFFFF) == (2, 0x00_FFFF_00))
        #expect(sim(0xFF, 0xFFFF) == (2, 0x00_FFFF_FF))
    }

    @Test func case_create_full() async throws {
        let network = await dumpSimpleNetwork(of: PayloadEnum4CasesRef.make_d)

        func sim(_ a: UInt64, _ b: UInt64, _ c: UInt64) -> (kind: UInt64, payload: UInt64) {
            let inputs: [String: UInt64] = [
                "0": a, "1": b, "2": c
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return (outputs["result_kind"]!, outputs["result_payload"]!)
        }

        #expect(sim(   0,      0,    0) == (3, 0x00_0000_00))
        #expect(sim(0x34, 0x1234, 0x98) == (3, 0x98_1234_34))
        #expect(sim(0x56, 0x2345, 0x76) == (3, 0x76_2345_56))
        #expect(sim(0xAB, 0xCDEF, 0x54) == (3, 0x54_CDEF_AB))
        #expect(sim(0xFF,      0, 0x00) == (3, 0x00_0000_FF))
        #expect(sim(   0, 0xFFFF,    0) == (3, 0x00_FFFF_00))
        #expect(sim(   0,      0, 0xFF) == (3, 0xFF_0000_00))
        #expect(sim(0xFF, 0xFFFF, 0xFF) == (3, 0xFF_FFFF_FF))
    }
}
