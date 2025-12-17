//
//  ShimmersInternalLogicTests/Boolean/Ternary.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@HardwareWire
fileprivate struct TernaryOperators {
    var result: Bool

    static func basic(v: Bool, t: Bool, f: Bool) -> Self {
        return .init(result: v ? t : f)
    }

    static func double1(a: Bool, b: Bool, c: Bool, d: Bool, e: Bool) -> Self {
        return .init(result: a ? b : c ? d : e)
    }

    static func double2(a: Bool, b: Bool, c: Bool, d: Bool, e: Bool) -> Self {
        return .init(result: a ? b ? c : d : e)
    }
}

@Suite(
    "Ternary Operators",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core
    )
)
struct TernaryOperatorTestSuite {
    @Test func basic() async {
        let network = await dumpSimpleNetwork(of: TernaryOperatorsRef.basic)

        func sim(_ v: Bool, _ t: Bool, _ f: Bool) -> Bool {
            let inputs: [String: UInt64] = [
                "0": UInt64(v ? 1 : 0),
                "1": UInt64(t ? 1 : 0),
                "2": UInt64(f ? 1 : 0)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return outputs["result"]! != 0
        }

        for v in [true, false] {
            for t in [true, false] {
                for f in [true, false] {
                    let truth = v ? t : f
                    #expect(sim(v, t, f) == truth, "\(v) ? \(t) : \(f)")
                }
            }
        }
    }

    @Test func double1() async {
        let network = await dumpSimpleNetwork(of: TernaryOperatorsRef.double1)

        func sim(_ a: Bool, _ b: Bool, _ c: Bool, _ d: Bool, _ e: Bool) -> Bool {
            let inputs: [String: UInt64] = [
                "0": UInt64(a ? 1 : 0),
                "1": UInt64(b ? 1 : 0),
                "2": UInt64(c ? 1 : 0),
                "3": UInt64(d ? 1 : 0),
                "4": UInt64(e ? 1 : 0)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return outputs["result"]! != 0
        }

        for a in [true, false] {
            for b in [true, false] {
                for c in [true, false] {
                    for d in [true, false] {
                        for e in [true, false] {
                            let truth = a ? b : c ? d : e
                            #expect(sim(a, b, c, d, e) == truth, "\(a) ? \(b) : \(c) ? \(d) : \(e)")
                        }
                    }
                }
            }
        }
    }

    @Test func double2() async {
        let network = await dumpSimpleNetwork(of: TernaryOperatorsRef.double2)

        func sim(_ a: Bool, _ b: Bool, _ c: Bool, _ d: Bool, _ e: Bool) -> Bool {
            let inputs: [String: UInt64] = [
                "0": UInt64(a ? 1 : 0),
                "1": UInt64(b ? 1 : 0),
                "2": UInt64(c ? 1 : 0),
                "3": UInt64(d ? 1 : 0),
                "4": UInt64(e ? 1 : 0)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return outputs["result"]! != 0
        }

        for a in [true, false] {
            for b in [true, false] {
                for c in [true, false] {
                    for d in [true, false] {
                        for e in [true, false] {
                            let truth = a ? b ? c : d : e
                            #expect(sim(a, b, c, d, e) == truth, "\(a) ? \(b) ? \(c) : \(d) : \(e)")
                        }
                    }
                }
            }
        }
    }
}
