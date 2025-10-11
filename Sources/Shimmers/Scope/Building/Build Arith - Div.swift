//
//  Shimmers/Scope/Building/Build Arith - Div.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

internal extension _SynthScope {
    func buildUnsignedDivider(
        lhs: [_WireID],
        rhs: [_WireID],
        width: Int
    ) -> (result: [_WireID], remainder: [_WireID]) {
        assert(lhs.count == width)
        assert(rhs.count <= width)

        let invertedRHS = rhs.map(!)

        var result = [_WireID](repeating: false, count: width)

        var curr = lhs
        // pad to full width
        while curr.count < width { curr.append(false) }

        for offset in (0..<width).reversed() {
            let partial = Array(curr[offset..<width])
            let (partialResult, carry, _) = buildAdder(lhs: partial, rhs: invertedRHS, carry: true, width: width)
            result[offset] = carry
            for i in offset..<width {
                curr[i] = addMux(of: carry, true: partialResult[i - offset], false: curr[i])
            }
        }

        return (result: result, remainder: curr)
    }
}
