//
//  Shimmers/Wire Types/Range/RangeRef - Collection.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension RangeRef: SequenceRef where BoundRef: StrideableRef, BoundRef.StrideRef: SignedIntegerRef {
    public typealias ElementRef = BoundRef
    public typealias IteratorRef = IndexingIteratorRef<RangeRef<BoundRef>>
}

extension RangeRef: CollectionRef where BoundRef: StrideableRef, BoundRef.StrideRef: SignedIntegerRef {

//    public typealias ElementRef = BoundRef
//    public typealias IteratorRef = IndexingIteratorRef<RangeRef<BoundRef>>
    public typealias IndexRef = BoundRef

    public var startIndex: BoundRef {
        lowerBound
    }

    public var endIndex: BoundRef {
        upperBound
    }

    @inlinable
    public subscript(position: BoundRef) -> BoundRef {
        return position
    }

    public var count: IntRef {
        return IntRef(startIndex.distance(to: endIndex))
    }

    public func index(after i: BoundRef) -> BoundRef {
        return _unsafeScopeIsolated { scope in
            scope.proveAssert(i != upperBound, type: .bound)
            let result = i.advanced(by: 1)
            return result
        }
    }

    public func index(_ i: BoundRef, offsetBy distance: IntRef) -> BoundRef {
        return _unsafeScopeIsolated { scope in
            let result = i.advanced(by: BoundRef.StrideRef(distance))
            scope.proveAssert(result < endIndex, type: .bound)
            return result
        }
    }

    public func index(_ i: BoundRef, offsetBy distance: IntRef, limitedBy limit: BoundRef) -> OptionalRef<BoundRef> {
        @_Local var result: OptionalRef<BoundRef>
        let distToLimit = i.distance(to: limit)
        _if(distance >= 0) {
            _if(distance > distToLimit) {
                result = nil
            }
            _if(distance <= distToLimit) {
                result = .init(wrapped: index(i, offsetBy: distance))
            }
        }
        _if(distance < 0) {
            _if(distance < distToLimit) {
                result = nil
            }
            _if(distance <= distToLimit) {
                result = .init(wrapped: index(i, offsetBy: distance))
            }
        }
        return result
    }

    public func distance(from start: BoundRef, to end: BoundRef) -> IntRef {
        return IntRef(end.distance(to: start))
    }
}
