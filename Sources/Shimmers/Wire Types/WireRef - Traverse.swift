//
//  Shimmers/Wire Types/WireRef - Traverse.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol _WireTraverser {
    mutating func skip(width: Int) -> Bool
    mutating func visit(wire: _WireID)
}

struct _SingleWireTraverser: _WireTraverser {
    public private(set) var wire: _WireID = false
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
    public mutating func visit(wire: _WireID) {
        if index == 0 {
            self.wire = wire
        }
        index -= 1
    }
}

struct AllWireTraverser: _WireTraverser {
    public private(set) var wires: [_WireID] = []

    @inlinable
    init(_ capacity: Int = 0) {
        if capacity != 0 {
            wires.reserveCapacity(capacity)
        }
    }

    @inlinable
    public mutating func skip(width: Int) -> Bool {
        return false
    }

    @inlinable
    public mutating func visit(wire: _WireID) {
        wires.append(wire)
    }
}

public protocol _WirePopper {
    mutating func pop() -> _WireID
}

public struct _ArrayWirePopper: _WirePopper {
    private var array: [_WireID]
    private var index: Int

    init(array: consuming [_WireID], startIndex: Int = 0) {
        self.array = array
        self.index = startIndex
    }
    public mutating func pop() -> _WireID {
        let bit = array[index]
        index += 1
        return bit
    }
}

public struct _ZeroWirePopper: _WirePopper {
    @inlinable
    public nonmutating func pop() -> _WireID {
        return false
    }
}

public struct _IntWirePopper<T: BinaryInteger>: _WirePopper {
    var value: T
    init(const: T) {
        self.value = const
    }
    public mutating func pop() -> _WireID {
        let bit = value & 1
        value >>= 1
        return _WireID(bit != 0)
    }
}


public struct _NegativeOneWirePopper: _WirePopper {
    var width: Int
    init(width: Int) {
        self.width = width
    }
    public mutating func pop() -> _WireID {
        width -= 1
        return width <= 0 ? true : false
    }
}
