//
//  ShimmersInternalLogicTests/Support/Simulator.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

@testable import Shimmers

func simulate(network: borrowing Network, inputs: consuming [String: UInt64]) -> [String: UInt64] {
    var values: [UInt32: Bool] = [0: false, 1: true]

    for (name, value) in inputs {
        guard network.inputs.keys.contains(name) else {
            fatalError("Input of network does not contain '\(name)'.")
        }
        for (index, bitID) in network.inputs[name]!.enumerated() {
            let value = (UInt64(1) << index) & value != 0
            values[bitID] = value
        }
    }

    var stack: [UInt32] = []
    for (_, bits) in network.outputs {
        for wireID in bits {
            stack.append(wireID & ~1)
        }
    }

    func get(id: UInt32) -> Bool? {
        let wireID: UInt32 = id & ~1
        guard let value = values[wireID] else {
            stack.append(wireID)
            return nil
        }
        return value != (id & 1 != 0)
    }

    while let wireID = stack.last {
        guard !values.keys.contains(wireID) else {
            stack.removeLast()
            continue
        }
        guard let gate = network.gates[wireID] else {
            fatalError("Attempting to query wire that's not drive and not a gate. Did you forget to a assign an input?")
        }
        var result: Bool
        switch gate {
        case .and(let a, let b):
            guard let a = get(id: a), let b = get(id: b) else { continue }
            result = a && b
        case .xor(let a, let b):
            guard let a = get(id: a), let b = get(id: b) else { continue }
            result = a != b
        case .mux(let s, let t, let f):
            guard let s = get(id: s), let t = get(id: t), let f = get(id: f) else { continue }
            result = s ? t : f
        }
        values[wireID] = result
        stack.removeLast()
    }

    var results: [String: UInt64] = [:]
    for (name, bits) in network.outputs {
        var field: UInt64 = 0
        for (index, wireID) in bits.enumerated() {
            let value = get(id: wireID)!
            field |= value ? 1 << index : 0
        }
        results[name] = field
    }
    return results
}
