//
//  Shimmers/Scope/Building/Build Arith - Shift.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension _SynthScope {
    func shiftRight(value: [_WireID], amount: [_WireID], signed: Bool) -> [_WireID] {
        var result: [_WireID] = value
        func readShifted(index: Int, shifted: Int) -> _WireID {
            if index + shifted >= result.count {
                // return high bit
                return signed ? (result.last ?? false) : false
            } else {
                return result[index + shifted]
            }
        }
        for (index, wireID) in amount.enumerated() {
            let shiftAmount = (index > 32) ? (1 << 32) : (1 &<< index)
            for i in value.indices {
                let shifted = readShifted(index: i, shifted: shiftAmount)
                let noshift = readShifted(index: i, shifted: 0)
                result[i] = addMux(of: wireID, true: shifted, false: noshift)
            }
        }
        return result
    }

    func shiftLeft(value: [_WireID], amount: [_WireID]) -> [_WireID] {
        var result: [_WireID] = value
        func readShifted(index: Int, shifted: Int) -> _WireID {
            if index - shifted < 0 {
                return false
            } else {
                return result[index - shifted]
            }
        }
        for (index, shift) in amount.enumerated() {
            let shiftAmount = (index > 32) ? (1 << 32) : (1 &<< index)
            for i in value.indices.reversed() {
                let shifted = readShifted(index: i, shifted: shiftAmount)
                let noshift = readShifted(index: i, shifted: 0)
                result[i] = addMux(of: shift, true: shifted, false: noshift)
            }
        }
        return result
    }
}
