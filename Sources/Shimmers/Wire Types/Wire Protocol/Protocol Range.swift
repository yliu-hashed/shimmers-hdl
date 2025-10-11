//
//  Shimmers/Wire Types/Wire Protocol/Protocol Range.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol RangeExpressionRef<BoundRef>: WireRef {
    associatedtype BoundRef: ComparableRef
//    func relative<C: Collection>(to collection: C) -> Range<Bound> where C.Index == Bound
    func contains(_ element: BoundRef) -> BoolRef
}
