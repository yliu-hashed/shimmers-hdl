//
//  Shimmers/Graph/Graph Builder.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

class GraphBuilder {
    struct InputPort {
        var name: String
        var minSeq: UInt32
        var maxSeq: UInt32
        var width: Int { Int(maxSeq) - Int(minSeq) + 1 }
    }

    struct OutputPort {
        var name: String
        var bits: [_WireID]
        var width: Int { bits.count }
    }

    internal var inputs: [InputPort] = []
    internal var outputs: [OutputPort] = []

    internal var gates: [Gate: UInt32] = [:]
    internal var modules: [Submodule] = []
    private var sequence: UInt32 = 1

    public enum Gate: Equatable, Hashable {
        case and(a: _WireID, b: _WireID)
        case xor(a: _WireID, b: _WireID)
        case mux(s: _WireID, t: _WireID, f: _WireID)
        case dff(d: _WireID)
    }

    internal struct Submodule {
        var name: String
        var inputs: [Port] = []
        var outputs: [Port] = []

        struct Port {
            var name: String
            var wires: [_WireID]
        }
    }
    
    func addNew(gate: Gate?) -> _WireID {
        let newSeq = sequence
        guard let gate = gate else {
            sequence += 1
            return _WireID(id: newSeq << 1)
        }
        if let seq = gates[gate] {
            return _WireID(id: seq << 1)
        }
        gates[gate] = newSeq
        sequence += 1
        return _WireID(id: newSeq << 1)
    }

    func addInput(width: Int, name: consuming String) -> [_WireID] {
        var input: [_WireID] = []
        input.reserveCapacity(width)
        for _ in 0..<width {
            input.append(addNew(gate: nil))
        }
        inputs.append(InputPort(name: name, minSeq: sequence - UInt32(width), maxSeq: sequence - 1))
        return input
    }

    func addOutput(wires: [_WireID], name: String) {
        let port = OutputPort(name: name, bits: wires)
        outputs.append(port)
    }
}
