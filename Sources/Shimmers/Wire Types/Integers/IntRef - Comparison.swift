//
//  Shimmers/Wire Types/Integers/IntRef - Comparison.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public extension _IntegerRefTemplate {
    static func == (lhs: Self, rhs: Self) -> BoolRef {
        return _unsafeScopeIsolated { scope in

            let lhsWires = lhs._getAllWireIDs()
            let rhsWires = rhs._getAllWireIDs()

            var joinWire: _WireID = false
            for index in 0..<Self._bitWidth {
                let wire = scope.addXOR(of: lhsWires[index], and: rhsWires[index])
                joinWire = scope.addOR(of: wire, and: joinWire)
            }
            return !BoolRef(wireID: joinWire)
        }
    }

    static func != (lhs: Self, rhs: Self) -> BoolRef {
        return !(lhs == rhs)
    }
}

public extension _UIntRefTemplate {
    internal static func smaller(lhs: Self, rhs: Self) -> BoolRef {
        return _unsafeScopeIsolated { scope in
            let result = scope.buildCompareSmaller(
                lhs: lhs.wireIDs,
                rhs: rhs.wireIDs,
                signed: false
            )
            return BoolRef(wireID: result)
        }
    }

    static func < (lhs: Self, rhs: Self) -> BoolRef {
        return smaller(lhs: lhs, rhs: rhs)
    }
}

public extension _SIntRefTemplate {
    internal static func smaller(lhs: Self, rhs: Self) -> BoolRef {
        return _unsafeScopeIsolated { scope in
            let result = scope.buildCompareSmaller(
                lhs: lhs.wireIDs,
                rhs: rhs.wireIDs,
                signed: true
            )
            return BoolRef(wireID: result)
        }
    }

    static func < (lhs: Self, rhs: Self) -> BoolRef {
        return smaller(lhs: lhs, rhs: rhs)
    }
}
