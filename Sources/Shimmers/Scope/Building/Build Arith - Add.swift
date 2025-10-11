//
//  Shimmers/Scope/Building/Build Arith - Add.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

internal extension _SynthScope {
    func buildAdder(
        lhs: borrowing [_WireID], lhsSigned: Bool = false,
        rhs: borrowing [_WireID], rhsSigned: Bool = false,
        carry: _WireID = false,
        width: Int
    ) -> (
        partialValue: [_WireID],
        carry: _WireID,
        carry2: _WireID
    ) {
        assert(lhs.count <= width)
        assert(rhs.count <= width)

        func getLHS(at index: Int) -> _WireID {
            guard index < lhs.count else { return lhsSigned ? lhs.last! : false }
            return lhs[index]
        }

        func getRHS(at index: Int) -> _WireID {
            guard index < rhs.count else { return rhsSigned ? rhs.last! : false }
            return rhs[index]
        }

        var curr = [_WireID](repeating: false, count: width)
        var carry: _WireID = carry
        var carry2: _WireID = false
        for i in 0..<width {
            let a = getLHS(at: i)
            let b = getRHS(at: i)
            let partialSum = addXOR(of: a, and: b)
            curr[i] = addXOR(of: carry, and: partialSum)
            carry2 = carry
            carry = addOR(
                of: addAND(of: a, and: b),
                and: addAND(of: partialSum, and: carry)
            )
        }
        return (curr, carry, carry2)
    }

    func buildNegator(
        wires: borrowing [_WireID],
    ) -> (
        partialValue: [_WireID],
        overflow: _WireID
    ) {
        let width = wires.count
        var curr = [_WireID](repeating: false, count: width)
        var carry: _WireID = true
        for i in 0..<width {
            let a = !wires[i]
            curr[i] = addXOR(of: a, and: carry)
            carry = addAND(of: a, and: carry)
        }
        return (curr, !carry)
    }

    func buildMagnitude(
        wires: borrowing [_WireID],
    ) -> (
        partialValue: [_WireID],
        overflow: _WireID
    ) {
        let isNegative = wires.last!
        let (negated, ovf) = buildNegator(wires: wires)
        let mag = buildMux(cond: isNegative, lhs: negated, rhs: wires)
        return (mag, ovf)
    }
}
