//
//  Shimmers/Graph/Simplify.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension GraphBuilder {
    func simplify() {
        var usage: [UInt32: Int] = [:]
        var unused: Set<UInt32> = []
        func updateUsage(for seq: UInt32, delta: Int) {
            guard seq != 0 else { return }
            let newUsage = (usage[seq] ?? 0) + delta
            usage[seq] = newUsage
            if newUsage == 0 {
                unused.insert(seq)
            } else {
                unused.remove(seq)
            }
            assert(newUsage >= 0)
        }

        func getUsage(for seq: UInt32) -> Int {
            return usage[seq] ?? 0
        }

        var table: [UInt32: Gate] = [:]
        for (gate, seq) in gates {
            if seq != 0 {
                table[seq] = gate
            }
            switch gate {
            case .and(let a, let b):
                updateUsage(for: a.id >> 1, delta: 1)
                updateUsage(for: b.id >> 1, delta: 1)
            case .xor(let a, let b):
                updateUsage(for: a.id >> 1, delta: 1)
                updateUsage(for: b.id >> 1, delta: 1)
            case .mux(let s, let t, let f):
                updateUsage(for: s.id >> 1, delta: 1)
                updateUsage(for: t.id >> 1, delta: 1)
                updateUsage(for: f.id >> 1, delta: 1)
            case .dff(let d):
                updateUsage(for: d.id >> 1, delta: 1)
            }
            updateUsage(for: seq, delta: 0)
        }

        for output in outputs {
            for bit in output.bits {
                updateUsage(for: bit.id >> 1, delta: 1)
            }
        }

        for module in modules {
            for port in module.inputs {
                for wire in port.wires {
                    updateUsage(for: wire.id >> 1, delta: 1)
                }
            }

            for port in module.outputs {
                for wire in port.wires {
                    updateUsage(for: wire.id >> 1, delta: 1)
                }
            }
        }
        
        while let firstUnusedSeq = unused.popFirst() {
            guard let gate = table[firstUnusedSeq] else { continue }
            gates.removeValue(forKey: gate)
            switch gate {
            case .and(let a, let b):
                updateUsage(for: a.id >> 1, delta: -1)
                updateUsage(for: b.id >> 1, delta: -1)
            case .xor(let a, let b):
                updateUsage(for: a.id >> 1, delta: -1)
                updateUsage(for: b.id >> 1, delta: -1)
            case .mux(let s, let t, let f):
                updateUsage(for: s.id >> 1, delta: -1)
                updateUsage(for: t.id >> 1, delta: -1)
                updateUsage(for: f.id >> 1, delta: -1)
            case .dff(let d):
                updateUsage(for: d.id >> 1, delta: -1)
            }
        }
    }
}
