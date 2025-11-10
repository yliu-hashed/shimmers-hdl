//
//  Shimmers/Wire Types/Array/InlineArrayRef.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public typealias BusRef = InlineArrayRef

public struct InlineArrayRef<let count: Int, ElementRef: WireRef>: WireRef {

    public static var _bitWidth: Int { count * ElementRef._bitWidth }
    internal var storage: [ElementRef]

    public func _getBit(at index: Int) -> _WireID {
        let elementWidth = ElementRef._bitWidth
        let elementIndex = index / elementWidth
        return storage[elementIndex]._getBit(at: index % elementWidth)
    }

    public func _traverse(using traverser: inout some _WireTraverser) {
        for i in 0..<count {
            if traverser.skip(width: ElementRef._bitWidth) { continue }
            storage[i]._traverse(using: &traverser)
        }
    }

    public init(_byPoppingBits builder: inout some _WirePopper) {
        storage = []
        storage.reserveCapacity(count)
        for _ in 0..<count {
            storage.append(ElementRef(_byPoppingBits: &builder))
        }
    }

    public init(_byPartWith parentName: String?, body: (_ name: String, _ bitWidth: Int) -> [_WireID]) {
        storage = []
        storage.reserveCapacity(count)
        for i in 0..<count {
            let name = _joinModuleName(base: parentName, suffix: "\(i)")
            let element = ElementRef(_byPartWith: name, body: body)
            storage.append(element)
        }
    }

    public func _applyPerPart(parentName: String?, body: (_ name: String, _ part: [_WireID]) -> Void) {
        for i in 0..<count {
            let name = _joinModuleName(base: parentName, suffix: "\(i)")
            storage[i]._applyPerPart(parentName: name, body: body)
        }
    }

    public init(repeating element: ElementRef) {
        storage = .init(repeating: element, count: count)
    }

    public var count: IntRef {
        return IntRef(count)
    }

    /// An inline array is never empty
    public var isEmpty: BoolRef {
        return BoolRef(count != 0)
    }
}
