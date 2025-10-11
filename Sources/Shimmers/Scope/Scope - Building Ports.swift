//
//  Shimmers/Scope/Scope - Building Ports.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension _SynthScope {
    func addInput<Ref: WireRef>(name: String) -> Ref {
        let wires: [_WireID] = builder.addInput(width: Ref._bitWidth, name: name)
        return Ref(from: wires)
    }

    func addInput(name: String, type: any WireRef.Type) -> any WireRef {
        let wires: [_WireID] = builder.addInput(width: type._bitWidth, name: name)
        return type.init(from: wires)
    }

    func addInput(name: String, bitWidth: Int) -> [_WireID] {
        let wires: [_WireID] = builder.addInput(width: bitWidth, name: name)
        return wires
    }

    func addInputBit(name: String) -> _WireID {
        let wireID = builder.addInput(width: 1, name: name)[0]
        return wireID
    }

    func addResult<Ref: WireRef>(_ ref: Ref, name: String) {
        let wires = ref._getAllWireIDs()
        builder.addOutput(wires: wires, name: name)
    }

    func addResult(_ wires: [_WireID], name: String) {
        builder.addOutput(wires: wires, name: name)
    }

    func addResultBit(wireID: _WireID, name: String) {
        builder.addOutput(wires: [wireID], name: name)
    }
}

extension _SynthScope {
    func reserveDFF(for type: any WireRef.Type) -> any WireRef {
        let width = type._bitWidth
        let reservations = builder.reserveDFF(width: width)
        return type.init(from: reservations)
    }

    func bindDFF(_ reservation: any WireRef, to data: any WireRef) {
        assert(type(of: reservation) == type(of: data))
        let reservationWires = reservation._getAllWireIDs()
        let dataWires = data._getAllWireIDs()
        builder.bindDFF(reservationWires, to: dataWires)
    }
}
