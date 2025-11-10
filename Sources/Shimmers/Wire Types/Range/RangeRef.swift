//
//  Shimmers/Wire Types/Range/RangeRef.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public struct RangeRef<BoundRef: ComparableRef>: RangeExpressionRef {

    @usableFromInline var lowerBound: BoundRef
    @usableFromInline var upperBound: BoundRef

    @inlinable
    public static var _bitWidth: Int { BoundRef._bitWidth * 2 }

    public func _traverse(using traverser: inout some _WireTraverser) {
        if !traverser.skip(width: BoundRef._bitWidth) {
            lowerBound._traverse(using: &traverser)
        }
        if !traverser.skip(width: BoundRef._bitWidth) {
            upperBound._traverse(using: &traverser)
        }
    }

    @inlinable
    internal init(lowerBound: BoundRef, upperBound: BoundRef) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    public init(_byPoppingBits builder: inout some _WirePopper) {
        lowerBound = BoundRef(_byPoppingBits: &builder)
        upperBound = BoundRef(_byPoppingBits: &builder)
    }

    @inlinable
    public var isEmpty: BoolRef {
        return lowerBound == upperBound
    }

    @inlinable
    public func contains(_ element: BoundRef) -> BoolRef {
        return (lowerBound <= element) && (element < upperBound)
    }
}

public func ..< <BoundRef: ComparableRef> (lhs: BoundRef, rhs: BoundRef) -> RangeRef<BoundRef> {
    return RangeRef(lowerBound: lhs, upperBound: rhs)
}
