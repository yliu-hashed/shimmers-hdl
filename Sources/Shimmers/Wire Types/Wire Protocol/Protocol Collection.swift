//
//  Shimmers/Wire Types/Wire Protocol/Protocol Collection.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol CollectionRef<ElementRef>: SequenceRef {

    override associatedtype ElementRef
    associatedtype IndexRef: ComparableRef
    associatedtype IteratorRef = IndexingIteratorRef<Self>

    var startIndex: IndexRef { get }
    var endIndex: IndexRef { get }

    subscript(position: IndexRef) -> ElementRef { get }
    var isEmpty: BoolRef { get }
    var count: IntRef { get }

    func index(after i: IndexRef) -> IndexRef
    func index(_ i: IndexRef, offsetBy distance: IntRef) -> IndexRef
    func index(_ i: IndexRef, offsetBy distance: IntRef, limitedBy limit: IndexRef) -> OptionalRef<IndexRef>
    func distance(from start: IndexRef, to end: IndexRef) -> IntRef
    func formIndex(after i: inout IndexRef)
}

public extension CollectionRef {
    func formIndex(after i: inout IndexRef) {
        i = index(after: i)
    }

    func formIndex(_ i: inout IndexRef, offsetBy distance: IntRef) {
        i = index(i, offsetBy: distance)
    }

    func formIndex(_ i: inout IndexRef, offsetBy distance: IntRef, limitedBy limit: IndexRef) -> BoolRef {
        @_Local var result: IndexRef = limit
        let advanced = index(i, offsetBy: distance, limitedBy: limit)
        _if(advanced._isValid) {
            result = advanced._unchecked_unwraped
        }
        i = result
        return advanced._isValid
    }
}

public extension CollectionRef where IteratorRef == IndexingIteratorRef<Self> {
    func makeIterator() -> IteratorRef {
        return .init(collectionRef: self, indexRef: startIndex)
    }
}
