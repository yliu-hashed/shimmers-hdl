//
//  Shimmers/Scope/Building/Build Arith - Mul.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

internal extension _SynthScope {
    func buildTruncatedUnsignedMultiply(
        lhs: [_WireID],
        rhs: [_WireID],
        width: Int
    ) -> (
        partialValue: [_WireID],
        overflow: _WireID
    ) {
        assert(lhs.count <= width)
        assert(rhs.count <= width)

        var curr = [_WireID](repeating: false, count: width)
        var overflowSet: Set<_WireID> = [false]

        for (offset, enableWire) in rhs.enumerated() {
            guard enableWire != false else { continue }
            var carry: _WireID = false
            for (index, dataWire) in lhs.enumerated() {
                let i = offset + index
                guard i < width else {
                    overflowSet.insert(carry)
                    overflowSet.insert(addAND(of: dataWire, and: enableWire))
                    carry = false
                    continue
                }
                let a = curr[i]
                let b = addAND(of: enableWire, and: dataWire)
                let partialSum = addXOR(of: a, and: b)
                curr[i] = addXOR(of: partialSum, and: carry)
                carry = addOR(
                    of: addAND(of: a, and: b),
                    and: addAND(of: partialSum, and: carry)
                )
            }
            overflowSet.insert(carry)
        }
        let overflow = addOR(reduce: overflowSet)
        return (curr, overflow)
    }

    func buildFullMultiply(
        lhs: [_WireID], lhsSigned: Bool,
        rhs: [_WireID], rhsSigned: Bool,
        width: Int
    ) -> [_WireID] {
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

        var curr = [_WireID](repeating: false, count: width * 2)

        for offset in 0..<(width * 2) {
            let enableWire = getLHS(at: offset)
            guard enableWire != false else { continue }

            var carry: _WireID = false
            for index in 0..<(width * 2 - offset) {
                let i = offset + index
                let dataWire = getRHS(at: index)
                let a = curr[i]
                let b = addAND(of: enableWire, and: dataWire)
                let partialSum = addXOR(of: a, and: b)
                curr[i] = addXOR(of: partialSum, and: carry)
                carry = addOR(
                    of: addAND(of: a, and: b),
                    and: addAND(of: partialSum, and: carry)
                )
            }
        }
        return curr
    }
}
