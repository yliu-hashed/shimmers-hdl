//
//  Shimmers/Wire Types/Queue/QueueRef.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public struct QueueRef<let count: Int, ElementRef: WireRef>: WireRef {

    public static var _bitWidth: Int {
        return Int.bitWidth * 2 + ElementRef._bitWidth * count + 1
    }

    var storage: [ElementRef]
    var readIndex: IntRef = 0
    var writeIndex: IntRef = 0
    var lapped: BoolRef = false

    public func _getBit(at index: Int) -> _WireID {
        assert(index >= 0, "Index out of range")
        let elementWidth = ElementRef._bitWidth
        var index = index
        if index < elementWidth * count {
            let elementIndex = index / elementWidth
            let bitIndex = index % elementWidth
            return storage[elementIndex]._getBit(at: bitIndex)
        }
        index -= elementWidth * count
        if index < Int.bitWidth {
            return readIndex._getBit(at: index)
        }
        index -= Int.bitWidth
        if index < Int.bitWidth {
            return writeIndex._getBit(at: index)
        }
        index -= Int.bitWidth
        if index == 0 {
            return lapped.wireID
        }
        fatalError("Index out of range")
    }

    public func _traverse(using traverser: inout some _WireTraverser) {
        for i in 0..<count {
            if traverser.skip(width: ElementRef._bitWidth) { continue }
            storage[i]._traverse(using: &traverser)
        }
        if !traverser.skip(width: Int.bitWidth) {
            readIndex._traverse(using: &traverser)
        }
        if !traverser.skip(width: Int.bitWidth) {
            writeIndex._traverse(using: &traverser)
        }
        traverser.visit(wire: lapped.wireID)
    }

    public init(_byPoppingBits builder: inout some _WirePopper) {
        storage = []
        storage.reserveCapacity(count)
        for _ in 0..<count {
            storage.append(.init(_byPoppingBits: &builder))
        }
        readIndex = .init(_byPoppingBits: &builder)
        writeIndex = .init(_byPoppingBits: &builder)
        lapped = .init(_byPoppingBits: &builder)
    }

    public init(_byPartWith parentName: String?, body: (_ name: String, _ bitWidth: Int) -> [_WireID]) {
        storage = []
        storage.reserveCapacity(count)
        for i in 0..<count {
            let name = _joinModuleName(base: parentName, suffix: "buffer_\(i)")
            let element = ElementRef(_byPartWith: name, body: body)
            storage.append(element)
        }
        readIndex  = IntRef(_byPartWith: _joinModuleName(base: parentName, suffix: "rptr"), body: body)
        writeIndex = IntRef(_byPartWith: _joinModuleName(base: parentName, suffix: "wptr"), body: body)
        lapped = BoolRef(_byPartWith: _joinModuleName(base: parentName, suffix: "lapped"), body: body)
    }

    public func _applyPerPart(parentName: String?, body: (_ name: String, _ part: [_WireID]) -> Void) {
        for i in 0..<count {
            let name = _joinModuleName(base: parentName, suffix: "buffer_\(i)")
            storage[i]._applyPerPart(parentName: name, body: body)
        }
        readIndex._applyPerPart(parentName: _joinModuleName(base: parentName, suffix: "rptr"), body: body)
        writeIndex._applyPerPart(parentName: _joinModuleName(base: parentName, suffix: "wptr"), body: body)
        lapped._applyPerPart(parentName: _joinModuleName(base: parentName, suffix: "lapped"), body: body)
    }

    public init() {
        storage = []
        storage.reserveCapacity(count)
        for _ in 0..<count {
            var zeroPopper = _ZeroWirePopper()
            storage.append(.init(_byPoppingBits: &zeroPopper))
        }
    }

    var isEmpty: BoolRef {
        return readIndex == writeIndex && !lapped
    }

    var isFull: BoolRef {
        return readIndex == writeIndex && lapped
    }

    @discardableResult
    public mutating func push(_ element: ElementRef) -> BoolRef {
        let isFull = isFull
        // set element
        for i in 0..<count {
            @_Local var value = storage[i]
            _if(!isFull && writeIndex == IntRef(i)) {
                value = element
            }
            storage[i] = value
        }
        // increment pointer
        @_Local var index = writeIndex
        _if(!isFull) {
            index &+= 1
            _if(index == IntRef(count)) {
                index = 0
            }
        }
        writeIndex = index
        return !isFull
    }

    @discardableResult
    public mutating func pop() -> OptionalRef<ElementRef> {
        let isEmpty = isEmpty
        // grab element
        var builder = _ZeroWirePopper()
        var result: ElementRef = .init(_byPoppingBits: &builder)
        for i in 0..<count {
            @_Local var value: ElementRef = .init(_byPoppingBits: &builder)
            _if(!isEmpty && readIndex == IntRef(i)) {
                value = storage[i]
            }
            result |= value
        }
        // increment pointer
        @_Local var index = readIndex
        _if(!isEmpty) {
            index &+= 1
            _if(index == IntRef(count)) {
                index = 0
            }
        }
        readIndex = index
        
        return .init(isValid: !isEmpty, wrapped: result)
    }
}
