//
//  ShimmersInternalLogicTests/Support/Dump Net.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

@testable import Shimmers

extension GraphBuilder {
    func clone() -> Network {
        var network = Network()
        for input in inputs {
            var bits: [UInt32] = []
            bits.reserveCapacity(input.width)
            for wireSeq in input.minSeq...input.maxSeq {
                bits.append(wireSeq << 1)
            }
            network.inputs[input.name] = bits
        }
        for output in outputs {
            var bits: [UInt32] = []
            bits.reserveCapacity(output.bits.count)
            for wire in output.bits {
                bits.append(wire.id)
            }
            network.outputs[output.name] = bits
        }
        network.gates.reserveCapacity(gates.count)
        for (gate, seq) in gates {
            let newGate: Network.Gate
            switch gate {
            case .and(let a, let b):
                newGate = .and(a: a.id, b: b.id)
            case .xor(let a, let b):
                newGate = .xor(a: a.id, b: b.id)
            case .mux(let s, let t, let f):
                newGate = .mux(s: s.id, t: t.id, f: f.id)
            case .dff(d: _):
                fatalError("DFF is not supported")
            }
            network.gates[seq << 1] = newGate
        }
        return network
    }
}

struct Network: Sendable {
    var inputs:  [String: [UInt32]] = [:]
    var outputs: [String: [UInt32]] = [:]
    var gates: [UInt32: Gate] = [:]

    enum Gate {
        case and(a: UInt32, b: UInt32)
        case xor(a: UInt32, b: UInt32)
        case mux(s: UInt32, t: UInt32, f: UInt32)
    }
}

private extension _SynthScope {
    func cloneNetwork() -> Network {
        builder.simplify()
        return builder.clone()
    }

    func dumpNetwork<O: WireRef, each I: WireRef>(of work: (repeat each I)->O) async -> Network {
        var index = -1
        func getName() -> String {
            index += 1
            return "\(index)"
        }

        let result = _ScopeControl.$currentScope.withValue(self) {
            work(repeat addInput(name: getName()) as each I)
        }
        result._addResult(parentName: nil, to: self)
        return cloneNetwork()
    }
}

func dumpSimpleNetwork<O: WireRef, each I: WireRef>(of work: @Sendable (repeat each I)->O, name: String = #function) async -> Network {
    let scope = _SynthScope(name: name, with: .testing)
    return await scope.dumpNetwork(of: work)
}
