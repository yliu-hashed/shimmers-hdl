//
//  Shimmers/Wire Types/WireRef - Logic.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public extension WireRef {
    func bit(at index: IntRef) -> BoolRef {
        return _unsafeScopeIsolated { scope in
            scope.proveAssert(index >= 0 && index < IntRef(Self._bitWidth), type: .bound)
            let indexWires = index.wireIDs
            var layerIndex: Int = 0
            var wires = _getAllWireIDs()
            while wires.count > 1 {
                let indexWire = indexWires[layerIndex]
                let pairCount = (wires.count + 1)/2
                for i in 0..<pairCount {
                    let lbit = wires[2*i]
                    let hbit = i == wires.count ? lbit : wires[2*i + 1]
                    wires[i] = scope.addMux(of: indexWire, true: hbit, false: lbit)
                }
                wires.removeLast(wires.count - pairCount)
                layerIndex += 1
            }
            return BoolRef(wireID: wires.first ?? false)
        }
    }

    func bit(at index: Int) -> BoolRef {
        let wire = _getBit(at: index)
        return BoolRef(wireID: wire)
    }

    static func &= (lhs: inout Self, rhs: Self) {
        lhs = lhs & rhs
    }

    static func |= (lhs: inout Self, rhs: Self) {
        lhs = lhs | rhs
    }

    static func ^= (lhs: inout Self, rhs: Self) {
        lhs = lhs ^ rhs
    }

    static func & (lhs: Self, rhs: Self) -> Self {
        return _unsafeScopeIsolated { scope in
            let lhsWires = lhs._getAllWireIDs()
            let rhsWires = rhs._getAllWireIDs()
            let wireIDs = (0..<Self._bitWidth).map { index in
                scope.addAND(of: lhsWires[index], and: rhsWires[index])
            }
            return Self(from: wireIDs)
        }
    }

    static func | (lhs: Self, rhs: Self) -> Self {
        return _unsafeScopeIsolated { scope in
            let lhsWires = lhs._getAllWireIDs()
            let rhsWires = rhs._getAllWireIDs()
            let wireIDs = (0..<Self._bitWidth).map { index in
                scope.addOR(of: lhsWires[index], and: rhsWires[index])
            }
            return Self(from: wireIDs)
        }
    }

    static func ^ (lhs: Self, rhs: Self) -> Self {
        return _unsafeScopeIsolated { scope in
            let lhsWires = lhs._getAllWireIDs()
            let rhsWires = rhs._getAllWireIDs()
            let wireIDs = (0..<Self._bitWidth).map { index in
                scope.addXOR(of: lhsWires[index], and: rhsWires[index])
            }
            return Self(from: wireIDs)
        }
    }

    func reduceAND() -> BoolRef {
        return _unsafeScopeIsolated { scope in
            let wires = _getAllWireIDs()
            let reduced = scope.addAND(reduce: wires)
            return BoolRef(wireID: reduced)
        }
    }

    func reduceOR() -> BoolRef {
        return _unsafeScopeIsolated { scope in
            let wires = _getAllWireIDs()
            let reduced = scope.addOR(reduce: wires)
            return BoolRef(wireID: reduced)
        }
    }

    static func ~= (lhs: inout Self, rhs: Self) {
        let rhsWires = rhs._getAllWireIDs().map { !$0 }
        lhs = Self(from: rhsWires)
    }

    static prefix func ~ (rhs: Self) -> Self {
        let rhsWires = rhs._getAllWireIDs().map { !$0 }
        return Self(from: rhsWires)
    }

    var nonzeroBitCount: IntRef {
        @_Local var count: IntRef = 0
        let wires = self._getAllWireIDs()
        for wire in wires {
            let isEnabled = BoolRef(wireID: wire)
            _if(isEnabled) {
                count = count + 1
            }
        }
        return count
    }

    var leadingZeroBitCount: IntRef {
        @_Local var count: IntRef = 0
        @_Local var stopped: BoolRef = false
        let wires = self._getAllWireIDs()
        for wire in wires.reversed() {
            let isEnabled = BoolRef(wireID: wire)
            _if(!stopped, !isEnabled) {
                count = count + 1
            }
            stopped = stopped || isEnabled
        }
        return count
    }

    var trailingZeroBitCount: IntRef {
        @_Local var count: IntRef = 0
        @_Local var stopped: BoolRef = false
        let wires = self._getAllWireIDs()
        for wire in wires {
            let isEnabled = BoolRef(wireID: wire)
            _if(!stopped, !isEnabled) {
                count = count + 1
            }
            stopped = stopped || isEnabled
        }
        return count
    }
}
