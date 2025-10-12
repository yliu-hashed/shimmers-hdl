//
//  ShimmersInternalLogicTests/Queue/Queue Push & Pop Basic.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct QueueBasic {
    var pop0: Optional<UInt8>
    var pop1: Optional<UInt8>
    var pop2: Optional<UInt8>
    var pop3: Optional<UInt8>
    var pop4: Optional<UInt8>

    var didPush: Bool

    static func push1(_ value: UInt8) -> Self {
        var queue = Queue<4, UInt8>()
        let didPush = queue.push(value)
        return .init(
            pop0: queue.pop(),
            pop1: queue.pop(),
            pop2: queue.pop(),
            pop3: queue.pop(),
            pop4: queue.pop(),
            didPush: didPush
        )
    }
}

@Suite(
    "Queue Push & Pop",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.extras,
    )
)
struct QueueInsertRemoveTestSuite {
    @Test func push1() async throws {
        let network = await dumpSimpleNetwork(of: QueueBasicRef.push1)

        func sim(_ value: UInt8) -> (pops: [UInt8?], didPush: Bool) {
            let inputs: [String: UInt64] = [
                "0": UInt64(value)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            var popResults = [UInt8?](repeating: nil, count: 5)
            for i in 0..<5 {
                let valid = outputs["pop\(i)_valid"]! != 0
                let value = UInt8(outputs["pop\(i)_value"]!)
                popResults[i] = valid ? value : nil
            }

            return (popResults, outputs["didPush"]! != 0)
        }

        #expect(sim(  0) == ([  0, nil, nil, nil, nil], true))
        #expect(sim(123) == ([123, nil, nil, nil, nil], true))
        #expect(sim(234) == ([234, nil, nil, nil, nil], true))
        #expect(sim(255) == ([255, nil, nil, nil, nil], true))
    }
}
