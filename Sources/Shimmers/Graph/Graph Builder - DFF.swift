//
//  Shimmers/Graph/Graph Builder - DFF.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension GraphBuilder {
    func reserveDFF(width: Int) -> [_WireID] {
        var input: [_WireID] = []
        input.reserveCapacity(width)
        for _ in 0..<width {
            input.append(addNew(gate: nil))
        }
        return input
    }

    func bindDFF(_ reservation: borrowing [_WireID], to data: borrowing [_WireID]) {
        assert(reservation.count == data.count)
        let width = reservation.count
        for i in 0..<width {
            let gate = Gate.dff(d: data[i])
            gates[gate] = reservation[i].id >> 1
        }
    }
}
