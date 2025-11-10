//
//  Shimmers/Wire Types/Array/InlineArrayRef - Iteration.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension InlineArrayRef {
    func _makeIteratorRef() -> InlineArrayIteratorRef<count, ElementRef> {
        return InlineArrayIteratorRef(arrayRef: self, indexRef: 0)
    }
}

public struct InlineArrayIteratorRef<let count: Int, ElementRef: WireRef> {

    public typealias ArrayRef = InlineArrayRef<count, ElementRef>

    private var indexRef: IntRef
    private var arrayRef: InlineArrayRef<count, ElementRef>

    @inlinable
    public static var _bitWidth: Int {
        return IntRef._bitWidth + ArrayRef._bitWidth
    }

    public func _getBit(at index: Int) -> _WireID {
        let indexWidth = IntRef._bitWidth
        if index < indexWidth {
            return indexRef._getBit(at: index)
        } else {
            return arrayRef._getBit(at: index - indexWidth)
        }
    }

    public func _traverse(using traverser: inout some _WireTraverser) {
        if !traverser.skip(width: IntRef._bitWidth) {
            indexRef._traverse(using: &traverser)
        }
        if !traverser.skip(width: ArrayRef._bitWidth) {
            arrayRef._traverse(using: &traverser)
        }
    }

    internal init(arrayRef: ArrayRef, indexRef: IntRef = 0) {
        self.indexRef = indexRef
        self.arrayRef = arrayRef
    }

    public init(_byPoppingBits builder: inout some _WirePopper) {
        indexRef = .init(_byPoppingBits: &builder)
        arrayRef = .init(_byPoppingBits: &builder)
    }

    public mutating func next() -> OptionalRef<ElementRef> {
        @_Local var element: OptionalRef<ElementRef> = nil
        @_Local var index = indexRef
        let endIndex = IntRef(count)
        _if(index != endIndex) {
            element = OptionalRef(wrapped: arrayRef[indexRef])
            index = indexRef + 1
        }
        indexRef = index
        return element
    }
}
