//
//  Shimmers/Graph/Graph Builder - Submodule.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension GraphBuilder {
    class HDLSubmoduleBuilder {
        unowned var owner: GraphBuilder
        var module: Submodule!

        fileprivate init(owner: GraphBuilder, name: consuming String) {
            self.owner = owner
            module = .init(name: name)
        }

        deinit {
            assert(module == nil, "Module builder freed without finishing")
        }

        func addInput(name: consuming String, wires: consuming [_WireID]) {
            let port = Submodule.Port(name: name, wires: wires)
            module.inputs.append(port)
        }

        func addOutput(name: consuming String, width: Int) -> [_WireID] {
            var wires: [_WireID] = []
            wires.reserveCapacity(width)
            for _ in 0..<width {
                wires.append(owner.addNew(gate: nil))
            }
            let port = Submodule.Port(name: name, wires: wires)
            module.outputs.append(port)
            return wires
        }

        func finish() {
            owner.modules.append(module)
            module = nil
        }
    }

    func addSubmodule(name: consuming String) -> HDLSubmoduleBuilder {
        return HDLSubmoduleBuilder(owner: self, name: name)
    }
}
