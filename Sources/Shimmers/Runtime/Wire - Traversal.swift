//
//  Shimmers/Runtime/Wire - Traversal.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol _BitTraverser {
    mutating func skip(width: Int) -> Bool
    mutating func visit(bit: Bool)
}

public extension _BitTraverser {
    mutating func visit(_ array: [Bool]) {
        guard array.count > 0 else { return }
        if !skip(width: array.count) {
            for bit in array {
                visit(bit: bit)
            }
        }
    }
}

struct _SingleBitTraverser: _BitTraverser {
    public private(set) var bit: Bool = false
    private var index: Int = 0

    @inlinable
    init(index: Int) {
        self.index = index
    }

    @inlinable
    public mutating func skip(width: Int) -> Bool {
        if index >= width || index < 0 {
            index -= width
            return true
        }
        return false
    }

    @inlinable
    public mutating func visit(bit: Bool) {
        if index == 0 {
            self.bit = bit
        }
        index -= 1
    }
}

public protocol _BitPopper {
    mutating func pop() -> Bool
}

public extension _BitPopper {
    mutating func pop(count: Int) -> [Bool] {
        var result: [Bool] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            result.append(pop())
        }
        return result
    }
}

struct _ArrayBitPopper: _BitPopper {
    private var array: [Bool]
    private var index: Int

    init(array: consuming [Bool], startIndex: Int = 0) {
        self.array = array
        self.index = startIndex
    }

    mutating func pop() -> Bool {
        let bit = array[index]
        index += 1
        return bit
    }
}

struct _ZeroBitPopper: _BitPopper {
    @inlinable
    nonmutating func pop() -> Bool {
        return false
    }
}

struct _IntBitPopper<T: BinaryInteger>: _BitPopper {
    var value: T
    init(const: T) {
        self.value = const
    }
    mutating func pop() -> Bool {
        let bit = value & 1
        value >>= 1
        return bit != 0
    }
}
