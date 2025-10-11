//
//  Shimmers/Graph/Graph Builder - Gates.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension GraphBuilder {

    func addAndGate(a: _WireID, b: _WireID) -> _WireID {
        if a ==  b { return a }
        if a == !b { return false }
        switch (a, b) {
        case (false, _): return false
        case (_, false): return false
        case (true, let x): return x
        case (let x, true): return x
        default: break
        }
        let minID = _WireID(id: min(a.id, b.id))
        let maxID = _WireID(id: max(a.id, b.id))
        return addNew(gate: .and(a: minID, b: maxID))
    }

    func addOrGate(a: _WireID, b: _WireID) -> _WireID {
        return !addAndGate(a: !a, b: !b)
    }

    func addXorGate(a: _WireID, b: _WireID) -> _WireID {
        if a ==  b { return false }
        if a == !b { return true  }
        switch (a, b) {
        case (true, let x): return !x
        case (let x, true): return !x
        case (false, let x): return x
        case (let x, false): return x
        default: break
        }
        var negated: UInt32 = 0
        if a.id & 1 != 0 { negated ^= 1 }
        if b.id & 1 != 0 { negated ^= 1 }
        let lhs = a.id & ~1
        let rhs = b.id & ~1

        let minID = _WireID(id: min(lhs, rhs))
        let maxID = _WireID(id: max(lhs, rhs))

        return _WireID(id: addNew(gate: .xor(a: minID, b: maxID)).id ^ negated)
    }

    func addMuxGate(s: _WireID, t: _WireID, f: _WireID) -> _WireID {
        switch (s, t, f) {
        case (true , let x, _): return x
        case (false, _, let x): return x
        case (let s, let x, false): return addAndGate(a: s, b: x)
        case (let s, false, let x): return addAndGate(a: !s, b: x)
        case (let s, true , let x): return addOrGate(a: s, b: x)
        case (let s, let x, true ): return addOrGate(a: !s, b: x)
        default: break
        }
        if t == f { return t }
        if t == !f { return addXorGate(a: s, b: f) }
        return addNew(gate: .mux(s: s, t: t, f: f))
    }

}
