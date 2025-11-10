//
//  Shimmers/Wire Types/Enum Support/Enum Raw Buffer.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public struct _EnumRawBuffer: Sendable {
    var wires: [_WireID]
    public init(length: Int) {
        assert(length >= 0)
        wires = [_WireID](repeating: false, count: length)
    }

    public func obtain<W: WireRef>(_ type: W.Type, at index: Int = 0) -> W {
        var popper = _ArrayWirePopper(array: wires, startIndex: index)
        return .init(_byPoppingBits: &popper)
    }

    public mutating func change<W: WireRef>(to value: W, at index: Int = 0) {
        let wires = value._getAllWireIDs()
        for (i, wire) in wires.enumerated() {
            self.wires[index + i] = wire
        }
    }

    public init(_byPoppingBits popper: inout some _WirePopper, length: Int) {
        wires = [_WireID](repeating: false, count: length)
        for i in 0..<length {
            wires[i] = popper.pop()
        }
    }

    public func _traverse(using traverser: inout some _WireTraverser) {
        for wire in wires {
            traverser.visit(wire: wire)
        }
    }

    public init(_byPartWith parentName: String?, body: (String, Int) -> [_WireID], length: Int) {
        let name = _joinModuleName(base: parentName, suffix: "content", preferBase: true)
        wires = body(name, length)
    }

    public func _applyPerPart(parentName: String?, body: (String, [_WireID]) -> Void) {
        let name = _joinModuleName(base: parentName, suffix: "content", preferBase: true)
        body(name, wires)
    }

    public func get(under types: borrowing [any WireRef.Type], at index: Int) -> any WireRef {
        var offset: Int = 0
        for type in types[0..<index] {
            offset += type._bitWidth
        }
        var popper = _ArrayWirePopper(array: wires, startIndex: offset)
        return types[index].init(_byPoppingBits: &popper)
    }
}
