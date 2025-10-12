//
//  ShimmersInternalLogicTests/Enum/Enum Rep Basic.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate enum BasicEnum4 {
    case a
    case b
    case c
    case d

    static func equal(_ lhs: BasicEnum4, _ rhs: BasicEnum4) -> Bool {
        return lhs == rhs
    }
}

@HardwareWire
fileprivate struct BasicEnum4Cases {
    var a: BasicEnum4
    var b: BasicEnum4
    var c: BasicEnum4
    var d: BasicEnum4

    static func get_cases() -> Self {
        return BasicEnum4Cases(a: .a, b: .b, c: .c, d: .d)
    }
}

@Suite(
    "Representation of Basic Enum",
    .tags(
        .ShimmersInternalTests_Logic.MacroExpansion.wire_enum,
    )
)
struct EnumBasicTestSuite {
    @Test func case_bitLength() async throws {
        #expect(BasicEnum4Ref._bitWidth == 2)
    }

    @Test func case_matching() async throws {
        let network = await dumpSimpleNetwork(of: BasicEnum4Ref.equal)

        func sim(_ a: UInt64, _ b: UInt64) -> Bool {
            let inputs: [String: UInt64] = [
                "0": UInt64(a),
                "1": UInt64(b)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return outputs["value"] != 0
        }

        let cases: [UInt64] = [0, 1, 2, 3]

        for i in cases {
            for j in cases {
                #expect(sim(i, j) == (i == j), "\(i) == \(j)")
            }
        }
    }

    @Test func case_create() async throws {
        let network = await dumpSimpleNetwork(of: BasicEnum4CasesRef.get_cases)

        func sim() -> (UInt64, UInt64, UInt64, UInt64) {
            let inputs: [String: UInt64] = [:]
            let outputs = simulate(network: network, inputs: inputs)
            return (outputs["a_kind"]!, outputs["b_kind"]!, outputs["c_kind"]!, outputs["d_kind"]!)
        }

        #expect(sim() == (0, 1, 2, 3))
    }
}

