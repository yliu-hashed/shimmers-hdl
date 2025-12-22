//
//  Shimmers/Wire Types/Wire Protocol/Protocol Iterator & Sequence.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol IteratorProtocolRef: WireRef {
    associatedtype ElementRef: WireRef
    mutating func next() -> OptionalRef<ElementRef>
}

public protocol SequenceRef<ElementRef>: WireRef { // where ElementRef == IteratorRef.ElementRef
    associatedtype ElementRef: WireRef //where Self.ElementRef == Self.IteratorRef.ElementRef
    associatedtype IteratorRef: IteratorProtocolRef
    func makeIterator() -> IteratorRef
}

public extension SequenceRef {
    @inlinable
    func _makeIterator() -> IteratorRef {
        return makeIterator()
    }
}
