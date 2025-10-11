//
//  Shimmers/Wire Types/Integers/IntRef - Math Add & Sub.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public extension _IntegerRefTemplate {
    func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: BoolRef) {
        return _unsafeScopeIsolated { scope in

            let lhsWires = _getAllWireIDs()
            let rhsWires = rhs._getAllWireIDs()

            let (sum, carry, carry2) = scope.buildAdder(
                lhs: lhsWires,
                rhs: rhsWires,
                width: Self._bitWidth
            )

            let overflow: _WireID
            if Self._isSigned {
                overflow = scope.addXOR(of: carry, and: carry2)
            } else {
                overflow = carry
            }

            return (
                partialValue: Self(from: sum),
                overflow: .init(wireID: overflow)
            )
        }
    }

    func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: BoolRef) {
        return _unsafeScopeIsolated { scope in
            let lhsWires = _getAllWireIDs()
            let rhsWires = rhs._getAllWireIDs().map(!)

            let (sum, carry, carry2) = scope.buildAdder(
                lhs: lhsWires,
                rhs: rhsWires,
                carry: true,
                width: Self._bitWidth
            )

            let overflow: _WireID
            if Self._isSigned {
                overflow = scope.addXOR(of: carry, and: carry2)
            } else {
                overflow = !carry
            }

            return (
                partialValue: Self(from: sum),
                overflow: .init(wireID: overflow)
            )
        }
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        let (v, o) = lhs.addingReportingOverflow(rhs)
        _proveAssert(!o, type: .overflowMath)
        return v
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        let (v, o) = lhs.subtractingReportingOverflow(rhs)
        _proveAssert(!o, type: .overflowMath)
        return v
    }
}
