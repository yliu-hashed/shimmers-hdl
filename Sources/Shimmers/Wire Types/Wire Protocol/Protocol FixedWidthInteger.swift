//
//  Shimmers/Wire Types/Wire Protocol/Protocol FixedWidthInteger.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

//FixedWidthInteger

public protocol _Dummy {

}

public protocol FixedWidthIntegerRef: _Dummy, BinaryIntegerRef where MagnitudeRef: FixedWidthIntegerRef & UnsignedIntegerRef, StrideRef: FixedWidthIntegerRef & SignedIntegerRef {

    @inlinable
    static var bitWidth: IntRef { get }

    static var max: Self { get }

    static var min: Self { get }

    func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: BoolRef)

    func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: BoolRef)

    func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: BoolRef)

    func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: BoolRef)

    func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: BoolRef)

    func multipliedFullWidth(by other: Self) -> (high: Self, low: Self.MagnitudeRef)

    func dividingFullWidth(_ dividend: (high: Self, low: Self.MagnitudeRef)) -> (quotient: Self, remainder: Self)

    static func &>>(lhs: Self, rhs: Self) -> Self

    static func &>>=(lhs: inout Self, rhs: Self)

    static func &<<(lhs: Self, rhs: Self) -> Self

    static func &<<=(lhs: inout Self, rhs: Self)

    static func &*(lhs: Self, rhs: Self) -> Self
}

public extension FixedWidthIntegerRef {
    var bitWidth: IntRef {
        return Self.bitWidth
    }

    var _bitWidth: Int {
        return Self._bitWidth
    }

    func multipliedFullWidth(by other: Self) -> (high: Self, low: MagnitudeRef) {
        fatalError("\(#function) not implemented (mul)")
    }

    func dividingFullWidth(_ dividend: (high: Self, low: Self.MagnitudeRef)) -> (quotient: Self, remainder: Self) {
        fatalError("\(#function) not implemented (div)")
    }

    static func &>> (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result &>>= rhs
        return result
    }

    static func &>> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS: BinaryIntegerRef {
      return lhs &>> Self(truncatingIfNeeded: rhs)
    }

    static func &>>= <RHS>(lhs: inout Self, rhs: RHS) where RHS: BinaryIntegerRef {
      lhs = lhs &>> rhs
    }

    static func &<< (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result &<<= rhs
        return result
    }

    static func &<< <RHS>(lhs: Self, rhs: RHS) -> Self where RHS: BinaryIntegerRef {
      return lhs &<< Self(truncatingIfNeeded: rhs)
    }

    static func &<<= <RHS>(lhs: inout Self, rhs: RHS) where RHS: BinaryIntegerRef {
      lhs = lhs &<< rhs
    }

    static func &+ (lhs: Self, rhs: Self) -> Self {
        return lhs.addingReportingOverflow(rhs).partialValue
    }

    static func &+= (lhs: inout Self, rhs: Self) {
        lhs = lhs &+ rhs
    }

    static func &- (lhs: Self, rhs: Self) -> Self {
        return lhs.subtractingReportingOverflow(rhs).partialValue
    }

    static func &-= (lhs: inout Self, rhs: Self) {
        lhs = lhs &- rhs
    }

    static func &*(lhs: Self, rhs: Self) -> Self {
        return rhs.multipliedReportingOverflow(by: lhs).partialValue
    }

    static func &*= (lhs: inout Self, rhs: Self) {
        lhs = lhs &* rhs
    }
}

public extension FixedWidthIntegerRef {
    static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS: BinaryIntegerRef {
        return _unsafeScopeIsolated { scope in
            let wires = scope.shiftRight(value: lhs._getAllWireIDs(), amount: rhs._getAllWireIDs(), signed: _isSigned)
            return Self(from: wires)
        }
    }

    static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS: BinaryIntegerRef {
        return _unsafeScopeIsolated { scope in
            let wires = scope.shiftLeft(value: lhs._getAllWireIDs(), amount: rhs._getAllWireIDs())
            return Self(from: wires)
        }
    }

    static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS: BinaryIntegerRef {
        lhs = lhs >> rhs
    }

    static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS: BinaryIntegerRef {
        lhs = lhs << rhs
    }

    init<T>(truncatingIfNeeded source: T) where T: BinaryIntegerRef {
        let wires = _unsafeScopeIsolated { scope in
            scope.extend(value: source._getAllWireIDs(), to: Self._bitWidth, signed: T._isSigned)
        }
        self.init(from: wires)
    }
}
