//
//  Shimmers/Runtime/Queue.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public struct Queue<let count: Int, Element: Wire>: Wire {

    var storage: [Element?]
    var readIndex: Int = 0
    var writeIndex: Int = 0
    var lapped: Bool = false

    public init() {
        storage = [Element?](repeating: nil, count: count)
    }

    public static var bitWidth: Int {
        return Int.bitWidth * 2 + Element.bitWidth * count + 1
    }

    public func bit(at index: Int) -> Bool {
        assert(index >= 0, "Index out of range")
        var index = index
        if index < Element.bitWidth * count {
            let elementIndex = index / Element.bitWidth
            let bitIndex = index % Element.bitWidth
            return storage[elementIndex].bit(at: bitIndex)
        }
        index -= Element.bitWidth * count
        if index < Int.bitWidth {
            return readIndex.bit(at: index)
        }
        index -= Int.bitWidth
        if index < Int.bitWidth {
            return writeIndex.bit(at: index)
        }
        index -= Int.bitWidth
        if index == 0 {
            return lapped
        }
        fatalError("Index out of range")
    }

    public func _traverse(using traverser: inout some _BitTraverser) {
        for i in 0..<count {
            if traverser.skip(width: Element.bitWidth) { continue }
            storage[i]._traverse(using: &traverser)
        }
        if !traverser.skip(width: Int.bitWidth) {
            readIndex._traverse(using: &traverser)
        }
        if !traverser.skip(width: Int.bitWidth) {
            writeIndex._traverse(using: &traverser)
        }
        traverser.visit(bit: lapped)
    }

    public init(byPoppingBits builder: inout some _BitPopper) {
        var storage: [Element] = []
        storage.reserveCapacity(count)
        for _ in 0..<count {
            storage.append(.init(byPoppingBits: &builder))
        }
        self.storage = storage

        readIndex = .init(byPoppingBits: &builder)
        writeIndex = .init(byPoppingBits: &builder)
        lapped = .init(byPoppingBits: &builder)
    }

    public var isEmpty: Bool {
        return readIndex == writeIndex && !lapped
    }

    public var isFull: Bool {
        return readIndex == writeIndex && lapped
    }

    @discardableResult
    public mutating func push(_ element: Element) -> Bool {
        if isFull { return false }
        storage[writeIndex] = element
        let wrap = writeIndex == count
        writeIndex = wrap ? writeIndex - count + 1 : writeIndex + 1
        return true
    }

    public mutating func pop() -> Element? {
        let value = storage[readIndex]
        let wrap = readIndex == count
        readIndex = wrap ? readIndex - count + 1 : readIndex + 1
        return value
    }
}
