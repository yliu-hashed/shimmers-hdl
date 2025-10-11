//
//  Shimmers/Runtime/Wire - Logic.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public extension Wire {
    static func &= (lhs: inout Self, rhs: Self) {
        let lhsWires = lhs._getAllBits()
        let rhsWires = rhs._getAllBits()
        let wireIDs = zip(lhsWires, rhsWires).map { $0 && $1 }
        lhs = Self(from: wireIDs)
    }

    static func |= (lhs: inout Self, rhs: Self) {
        let lhsWires = lhs._getAllBits()
        let rhsWires = rhs._getAllBits()
        let wireIDs = zip(lhsWires, rhsWires).map { $0 || $1 }
        lhs = Self(from: wireIDs)
    }

    static func ^= (lhs: inout Self, rhs: Self) {
        let lhsWires = lhs._getAllBits()
        let rhsWires = rhs._getAllBits()
        let wireIDs = zip(lhsWires, rhsWires).map { $0 != $1 }
        lhs = Self(from: wireIDs)
    }

    static func & (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result &= rhs
        return result
    }

    static func | (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result |= rhs
        return result
    }

    static func ^ (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result ^= rhs
        return result
    }

    func reduceAND() -> Bool {
        let bits = _getAllBits()
        return bits.reduce(true) { $0 && $1 }
    }

    func reduceOR() -> Bool {
        let bits = _getAllBits()
        return bits.reduce(false) { $0 || $1 }
    }

    static prefix func ~ (rhs: Self) -> Self {
        let bits = rhs._getAllBits().map(!)
        return Self(from: bits)
    }

    var nonzeroBitCount: Int {
        return _getAllBits().count { $0 }
    }

    var leadingZeroBitCount: Int {
        var count: Int = 0
        let bits = _getAllBits()
        for bit in bits.reversed() {
            if bit { break }
            count += 1
        }
        return count
    }

    var trailingZeroBitCount: Int {
        var count: Int = 0
        let bits = _getAllBits()
        for bit in bits {
            if bit { break }
            count += 1
        }
        return count
    }
}
