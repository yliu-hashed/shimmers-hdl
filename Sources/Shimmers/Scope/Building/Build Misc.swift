//
//  Shimmers/Scope/Building/Build Misc.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension _SynthScope {
    @usableFromInline
    func buildMux(cond: _WireID, lhs: [_WireID], rhs: [_WireID]) -> [_WireID] {
        assert(lhs.count == rhs.count)
        var result: [_WireID] = []
        for i in 0..<lhs.count {
            let l = lhs[i]
            let r = rhs[i]
            if l == r {
                result.append(l)
            } else {
                result.append(addMux(of: cond, true: l, false: r))
            }
        }
        return result
    }
}

extension _SynthScope {
    @usableFromInline
    func extend(value: [_WireID], to amount: Int, signed: Bool) -> [_WireID] {
        if amount <= value.count {
            // truncation
            return Array(value.prefix(amount))
        } else {
            let signBit = signed ? (value.last ?? false) : false
            var bits = value
            for _ in value.count ..< amount {
                bits.append(signBit)
            }
            return bits
        }
    }
}

@usableFromInline
internal func downMUX<T: WireRef>(_ inputs: borrowing [T], at index: IntRef) -> T {
    assert(!inputs.isEmpty)
    return _unsafeScopeIsolated { scope in
        let indexWires = index.wireIDs
        var layerIndex: Int = 0
        var wires = inputs.map { $0._getAllWireIDs() }
        while wires.count > 1 {
            let indexWire = indexWires[layerIndex]
            let pairCount = (wires.count + 1)/2
            for i in 0..<pairCount {
                let wiresL = wires[2*i]
                let wiresH = (2*i+1) == wires.count ? wiresL : wires[2*i+1]
                wires[i] = scope.buildMux(cond: indexWire, lhs: wiresH, rhs: wiresL)
            }
            wires.removeLast(wires.count - pairCount)
            layerIndex += 1
        }
        return T(from: wires.first!)
    }
}
