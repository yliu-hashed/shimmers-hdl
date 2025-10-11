//
//  Shimmers/Scope/Scope - Building Gates.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension _SynthScope {

    @usableFromInline
    func addAND(of lhs: _WireID, and rhs: _WireID) -> _WireID {
        let resultID = builder.addAndGate(a: lhs, b: rhs)
        cnfBuilder.addAnd(a: lhs, b: rhs, out: resultID)
        return resultID
    }

    @usableFromInline
    func addOR(of lhs: _WireID, and rhs: _WireID) -> _WireID {
        let resultID = builder.addOrGate(a: lhs, b: rhs)
        cnfBuilder.addOr(a: lhs, b: rhs, out: resultID)
        return resultID
    }

    @usableFromInline
    func addXOR(of lhs: _WireID, and rhs: _WireID) -> _WireID {
        let resultID = builder.addXorGate(a: lhs, b: rhs)
        cnfBuilder.addXor(a: lhs, b: rhs, out: resultID)
        return resultID
    }

    @usableFromInline
    func addMux(of wire: _WireID, true t: _WireID, false f: _WireID) -> _WireID {
        let resultID = builder.addMuxGate(s: wire, t: t, f: f)
        cnfBuilder.addMux(s: wire, a: t, b: f, out: resultID)
        return resultID
    }

    @usableFromInline
    func addAND(reduce collection: some Collection<_WireID>) -> _WireID {
        var wire: _WireID = true
        for src in collection {
            wire = addAND(of: wire, and: src)
        }
        return wire
    }

    @usableFromInline
    func addOR(reduce collection: some Collection<_WireID>) -> _WireID {
        var wire: _WireID = false
        for src in collection {
            wire = addOR(of: wire, and: src)
        }
        return wire
    }
}
