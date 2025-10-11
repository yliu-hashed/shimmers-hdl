//
//  Shimmers/Scope/Building/Build Arith - Compare.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

internal extension _SynthScope {
    func buildCompareSmaller(
        lhs: [_WireID],
        rhs: [_WireID],
        signed: Bool
    ) -> _WireID {
        let width = max(lhs.count, rhs.count)

        func getLHS(at index: Int) -> _WireID {
            guard index < lhs.count else { return signed ? lhs.last! : false }
            return lhs[index]
        }

        func getRHS(at index: Int) -> _WireID {
            guard index < rhs.count else { return signed ? rhs.last! : false }
            return rhs[index]
        }

        var lastSmall: _WireID = false
        for index in 0..<width {
            let isMSB = signed && (index == width - 1)

            let lhsWire = getLHS(at: index)
            let rhsWire = getRHS(at: index)

            let diff = addXOR(of: lhsWire, and: rhsWire)
            lastSmall = addMux(of: diff, true: isMSB ? lhsWire : rhsWire, false: lastSmall)
        }
        return lastSmall
    }
}
