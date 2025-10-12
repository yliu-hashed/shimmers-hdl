//
//  ShimmersInternalLogicTests/Construction/Con Mutate Function.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct Member {
    var value: UInt8

    mutating func work() {
        value &+= 3
    }
}

@HardwareWire
fileprivate struct Host {
    var result: UInt8

    static func work(decider: UInt8) -> Self {
        var member: Member = .init(value: 111)
        if decider > 2 {
            member.work()
        }
        return .init(result: member.value)
    }
}

@Suite(
    "Construction - Mutate Member",
    .tags(
        .ShimmersInternalTests_Logic.MacroExpansion.codeblock_if,
    )
)
struct ConMutateMemberTestSuite {
    @Test func simple() async {
        let network = await dumpSimpleNetwork(of: HostRef.work)

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
        #expect(sim(3) == 114)
        #expect(sim(4) == 114)
        #expect(sim(5) == 114)
    }
}
