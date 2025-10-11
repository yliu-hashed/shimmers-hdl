//
//  Shimmers/Wire Types/Wire Protocol/Protocol BinaryInteger.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol BinaryIntegerRef: NumericRef, StrideableRef
where MagnitudeRef : BinaryIntegerRef,
      MagnitudeRef.MagnitudeRef == MagnitudeRef
{
    static var isSigned: BoolRef { get }

    static var _isSigned: Bool { get }

    init<T: BinaryIntegerRef>(_ source: T)

    init<T: BinaryIntegerRef>(truncatingIfNeeded source: T)

    init<T: BinaryIntegerRef>(clamping source: T)

    var bitWidth: IntRef { get }

    var _bitWidth: Int { get }

    static func / (lhs: Self, rhs: Self) -> Self

    static func /= (lhs: inout Self, rhs: Self)

    static func % (lhs: Self, rhs: Self) -> Self

    static func %= (lhs: inout Self, rhs: Self)

    override static func + (lhs: Self, rhs: Self) -> Self

    override static func += (lhs: inout Self, rhs: Self)

    override static func - (lhs: Self, rhs: Self) -> Self

    override static func -= (lhs: inout Self, rhs: Self)

    override static func * (lhs: Self, rhs: Self) -> Self

    override static func *= (lhs: inout Self, rhs: Self)

    static func >> <RHS: BinaryIntegerRef>(lhs: Self, rhs: RHS) -> Self

    static func >>= <RHS: BinaryIntegerRef>(lhs: inout Self, rhs: RHS)

    static func << <RHS: BinaryIntegerRef>(lhs: Self, rhs: RHS) -> Self

    static func <<= <RHS: BinaryIntegerRef>(lhs: inout Self, rhs: RHS)

    func quotientAndRemainder(dividingBy rhs: Self) -> (quotient: Self, remainder: Self)

    func isMultiple(of other: Self) -> BoolRef

    func signum() -> Self
}

public extension BinaryIntegerRef {

    init() {
        self = .zero
    }

    func signum() -> Self {
        @_Local var result: Self = .zero
        _if(self < Self.zero) {
            result = -1
        }
        _if(self > Self.zero) {
            result = 1
        }
        return result
    }

    @inlinable
    func quotientAndRemainder(dividingBy rhs: Self) -> (quotient: Self, remainder: Self) {
        return (quotient: self / rhs, remainder: self % rhs)
    }

    @inlinable
    func isMultiple(of other: Self) -> BoolRef {
        @_Local var result: BoolRef = (self.magnitude % other.magnitude) == 0
        _if(other == 0) {
            result = self == 0
        }
        return result
    }

    static func << (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result <<= rhs
        return result
    }

    static func >> (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result >>= rhs
        return result
    }

    func distance(to other: Self) -> IntRef {
        @_Local var result: IntRef
        if !Self._isSigned {
            let bigger = self > other
            _if(bigger) {
                let v = IntRef.exactly(self - other)
                _proveAssert(v._isValid, type: .overflowConvert, msg: "Distance is not representable in Int")
                result = v._unchecked_unwraped
            }
            _if(!bigger) {
                let v = IntRef.exactly(other - self)
                _proveAssert(v._isValid, type: .overflowConvert, msg: "Distance is not representable in Int")
                result = v._unchecked_unwraped
            }
        } else {
            let isNegative = self < Self.zero
            let sameSign = isNegative == (other < Self.zero)
            _if(sameSign) {
                let v = IntRef.exactly(other - self)
                _proveAssert(v._isValid, type: .overflowConvert, msg: "Distance is not representable in Int")
                result = v._unchecked_unwraped
            }
            _if(!sameSign) {
                let v = IntRef.exactly(self.magnitude + other.magnitude)
                _proveAssert(v._isValid, type: .overflowConvert, msg: "Distance is not representable in Int")
                result = isNegative._mux(v._unchecked_unwraped, else: -v._unchecked_unwraped)
            }
        }
        return result
    }

    @inlinable
    func advanced(by n: IntRef) -> Self {
        @_Local var result: Self
        if Self._isSigned {
            let smaller = self.bitWidth < n.bitWidth
            _if(smaller) {
                result = Self(IntRef(truncatingIfNeeded: self) + n)
            }
            _if(!smaller) {
                result = self + Self(truncatingIfNeeded: n)
            }
        } else {
            //            let isNegative = n < (0 as IntRef)
            //            __with(isNegative) {
            //                result = self - Self(UIntRef(bitPattern: ~n &+ 1))
            //            }
            // TODO: FIX ME
            fatalError("\(#function) not implemented")
        }

        //        if Self.isSigned {
        //            return self.bitWidth < n.bitWidth
        //            ? Self(Int(truncatingIfNeeded: self) + n)
        //            : self + Self(truncatingIfNeeded: n)
        //        } else {
        //            return n < (0 as Int)
        //            ? self - Self(UInt(bitPattern: ~n &+ 1))
        //            : self + Self(UInt(bitPattern: n))
        //        }
        return result
    }
}


public extension BinaryIntegerRef {
    @inlinable
    static func == <Other>(lhs: Self, rhs: Other) -> BoolRef where Other : BinaryIntegerRef {
        if Self._isSigned == Other._isSigned {
            if Self._bitWidth >= rhs._bitWidth {
                return lhs == Self(truncatingIfNeeded: rhs)
            } else {
                return Self(truncatingIfNeeded: lhs) == rhs
            }
        }

        if Self._isSigned {
            if Self._bitWidth > rhs._bitWidth {
                return lhs == Self(truncatingIfNeeded: rhs)
            } else {
                return (lhs >= Self.zero) && Other(truncatingIfNeeded: lhs) == rhs
            }
        }

        if Self._bitWidth < rhs._bitWidth {
            return Self(truncatingIfNeeded: lhs) == rhs
        } else {
            return (lhs >= Self.zero) && lhs == Self(truncatingIfNeeded: rhs)
        }
    }

    @inlinable
    static func != <Other>(lhs: Self, rhs: Other) -> BoolRef where Other : BinaryIntegerRef {
        return !(lhs == rhs)
    }

    static func < <Other>(lhs: Self, rhs: Other) -> BoolRef where Other : BinaryIntegerRef {

        if Self._isSigned == Other._isSigned {
            if lhs._bitWidth >= rhs._bitWidth {
                return lhs < Self(truncatingIfNeeded: rhs)
            } else {
                return Other(truncatingIfNeeded: lhs) < rhs
            }
        }

        if Self._isSigned {
            if lhs._bitWidth > rhs._bitWidth {
                return lhs < Self(truncatingIfNeeded: rhs)
            } else {
                return (lhs < Self.zero || Other(truncatingIfNeeded: lhs) < rhs)
            }
        }

        if Self._bitWidth < rhs._bitWidth {
            return Other(truncatingIfNeeded: lhs) < rhs
        } else {
            return (rhs > Other.zero) && lhs < Self(truncatingIfNeeded: rhs)
        }
    }

    @inlinable
    static func <= <Other>(lhs: Self, rhs: Other) -> BoolRef where Other : BinaryIntegerRef {
        return !(rhs < lhs)
    }

    @inlinable
    static func >= <Other>(lhs: Self, rhs: Other) -> BoolRef where Other : BinaryIntegerRef {
        return !(lhs < rhs)
    }

    @inlinable
    static func > <Other>(lhs: Self, rhs: Other) -> BoolRef where Other : BinaryIntegerRef {
        return rhs < lhs
    }
}
