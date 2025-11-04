//
//  ShimmersInternalLogicTests/Boolean/Boolean.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@HardwareWire
fileprivate struct BooleanGates {
    var result: Bool

    static func basic(a: Bool, b: Bool, c: Bool, d: Bool) -> Self {
        return .init(result: a && b || c != d)
    }
}

@Suite(
    "Boolean Gates",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core
    )
)
struct BooleanGatesTestSuite {
    @Test func basic() async throws {
        let network = await dumpSimpleNetwork(of: BooleanGatesRef.basic)

        func sim(_ a: Bool, _ b: Bool, _ c: Bool, _ d: Bool) -> Bool {
            let inputs: [String: UInt64] = [
                "0": UInt64(a ? 1 : 0),
                "1": UInt64(b ? 1 : 0),
                "2": UInt64(c ? 1 : 0),
                "3": UInt64(d ? 1 : 0)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return outputs["result"]! != 0
        }

        for a in [true, false] {
            for b in [true, false] {
                for c in [true, false] {
                    for d in [true, false] {
                        let truth = a && b || c != d
                        #expect(sim(a, b, c, d) == truth, "\(a) && \(b) || \(c) != \(d)")
                    }
                }
            }
        }
    }
}
