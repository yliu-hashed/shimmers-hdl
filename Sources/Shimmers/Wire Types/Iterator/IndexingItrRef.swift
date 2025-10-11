//
//  Shimmers/Wire Types/Iterator/IndexingItrRef.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public struct IndexingIteratorRef<ElementsRef: CollectionRef>: IteratorProtocolRef {
    public typealias ElementRef = ElementsRef.ElementRef

    private var indexRef: ElementsRef.IndexRef
    private let collectionRef: ElementsRef

    @inlinable
    public static var _bitWidth: Int {
        return ElementsRef.IndexRef._bitWidth + ElementsRef._bitWidth
    }

    public func _getBit(at index: Int) -> _WireID {
        let indexWidth = ElementsRef.IndexRef._bitWidth
        if index < indexWidth {
            return indexRef._getBit(at: index)
        } else {
            return collectionRef._getBit(at: index - indexWidth)
        }
    }

    public func _traverse(using traverser: inout some _WireTraverser) {
        if !traverser.skip(width: ElementsRef.IndexRef._bitWidth) {
            indexRef._traverse(using: &traverser)
        }
        if !traverser.skip(width: ElementsRef._bitWidth) {
            collectionRef._traverse(using: &traverser)
        }
    }

    internal init(collectionRef: ElementsRef, indexRef: ElementsRef.IndexRef) {
        self.indexRef = indexRef
        self.collectionRef = collectionRef
    }

    public init(byPoppingBits builder: inout some _WirePopper) {
        indexRef = .init(byPoppingBits: &builder)
        collectionRef = .init(byPoppingBits: &builder)
    }

    public mutating func next() -> OptionalRef<ElementRef> {
        @_Local var element: OptionalRef<ElementRef> = nil
        @_Local var index = indexRef
        let endIndex = collectionRef.endIndex
        _if(index != endIndex) {
            element = OptionalRef(wrapped: collectionRef[indexRef])
            index = collectionRef.index(after: indexRef)
        }
        indexRef = index
        return element
    }
}
