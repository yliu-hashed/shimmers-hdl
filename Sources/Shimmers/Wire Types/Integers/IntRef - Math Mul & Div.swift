//
//  Shimmers/Wire Types/Integers/IntRef - Math Mul & Div.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public extension _IntegerRefTemplate {
    func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: BoolRef) {
        return _unsafeScopeIsolated { scope in
            let wiresX = _getAllWireIDs()
            let wiresY = rhs._getAllWireIDs()
            if Self._isSigned {
                let full = scope.buildFullMultiply(
                    lhs: wiresX, lhsSigned: true,
                    rhs: wiresY, rhsSigned: true,
                    width: Self._bitWidth
                )
                let sign = full.last!
                let lowerBits = Array(full[0..<_bitWidth])
                var overflowSet: Set<_WireID> = []
                for wire in full[(_bitWidth - 1)..<(_bitWidth * 2)] {
                    overflowSet.insert(scope.addXOR(of: sign, and: wire))
                }
                let ovf = scope.addOR(reduce: overflowSet)
                return (Self(from: lowerBits), BoolRef(wireID: ovf))
            } else {
                let (product, mulOvf) = scope.buildTruncatedUnsignedMultiply(
                    lhs: wiresX,
                    rhs: wiresY,
                    width: Self._bitWidth
                )
                return (Self(from: product), BoolRef(wireID: mulOvf))
            }
        }
    }

    func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: BoolRef) {
        return _unsafeScopeIsolated { scope in
            let wiresX = _getAllWireIDs()
            let wiresY = rhs._getAllWireIDs()
            let isZero = !scope.addOR(reduce: wiresY)

            let partial: [_WireID]
            let partialOvf: _WireID
            if Self._isSigned {
                let invertFinal = scope.addXOR(of: wiresX.last!, and: wiresY.last!)
                let magX = scope.buildMagnitude(wires: wiresX).partialValue
                let magY = scope.buildMagnitude(wires: wiresY).partialValue
                let (quotient, _) = scope.buildUnsignedDivider(
                    lhs: magX,
                    rhs: magY,
                    width: Self._bitWidth
                )
                let (negated, _) = scope.buildNegator(wires: quotient)
                partial = scope.buildMux(cond: invertFinal, lhs: negated, rhs: quotient)
                partialOvf = (self == -128 && rhs == -1).wireID
            } else {
                let (quotient, _) = scope.buildUnsignedDivider(
                    lhs: wiresX,
                    rhs: wiresY,
                    width: Self._bitWidth
                )
                partial = quotient
                partialOvf = false
            }
            let result = scope.buildMux(cond: isZero, lhs: wiresX, rhs: partial)
            return (Self(from: result), BoolRef(wireID: scope.addOR(of: partialOvf, and: isZero)))
        }
    }

    func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: BoolRef) {
        return _unsafeScopeIsolated { scope in
            let wiresX = _getAllWireIDs()
            let wiresY = rhs._getAllWireIDs()
            let isZero = !scope.addOR(reduce: wiresY)

            let partial: [_WireID]
            let partialOvf: _WireID
            if Self._isSigned {
                let invertFinal = wiresX.last!
                let magX = scope.buildMagnitude(wires: wiresX).partialValue
                let magY = scope.buildMagnitude(wires: wiresY).partialValue
                let (_, remainder) = scope.buildUnsignedDivider(
                    lhs: magX,
                    rhs: magY,
                    width: Self._bitWidth
                )
                let (negated, _) = scope.buildNegator(wires: remainder)
                partial = scope.buildMux(cond: invertFinal, lhs: negated, rhs: remainder)
                partialOvf = (self == -128 && rhs == -1).wireID
            } else {
                let (_, remainder) = scope.buildUnsignedDivider(
                    lhs: wiresX,
                    rhs: wiresY,
                    width: Self._bitWidth
                )
                partial = remainder
                partialOvf = false
            }
            return (Self(from: partial), BoolRef(wireID: scope.addOR(of: partialOvf, and: isZero)))
        }
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        let (v, o) = lhs.multipliedReportingOverflow(by: rhs)
        _unsafeScopeIsolated { scope in
            scope.proveAssert(!o, type: .overflowMath)
        }
        return v
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        let (v, o) = lhs.dividedReportingOverflow(by: rhs)
        _unsafeScopeIsolated { scope in
            scope.proveAssert(!o, type: .overflowMath)
        }
        return v
    }

    static func % (lhs: Self, rhs: Self) -> Self {
        let (v, o) = lhs.remainderReportingOverflow(dividingBy: rhs)
        _unsafeScopeIsolated { scope in
            scope.proveAssert(!o, type: .overflowMath)
        }
        return v
    }

    static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }

    static func %= (lhs: inout Self, rhs: Self) {
        lhs = lhs % rhs
    }
}
