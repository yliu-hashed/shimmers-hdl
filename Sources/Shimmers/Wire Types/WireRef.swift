//
//  Shimmers/Wire Types/WireRef.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol WireRef: Sendable {

    @inlinable
    nonisolated static var _bitWidth: Int { get }

    // bitwise initialize and traversal

    init(byPoppingBits: inout some _WirePopper)
    func _getBit(at index: Int) -> _WireID
    func _traverse(using traverser: inout some _WireTraverser)

    // hiearchical initialize and traversal

    init(parentName: String?, body: (_ name: String, _ bitWidth: Int) -> [_WireID])
    func _applyPerPart(parentName: String?, body: (_ name: String, _ part: [_WireID]) -> Void)

    // comparison

    static func == (lhs: Self, rhs: Self) -> BoolRef
    static func != (lhs: Self, rhs: Self) -> BoolRef
}

public extension WireRef {
    static func == (lhs: Self, rhs: Self) -> BoolRef {
        return _unsafeScopeIsolated { scope in

            let lhsWires = lhs._getAllWireIDs()
            let rhsWires = rhs._getAllWireIDs()

            var joinWire: _WireID = false
            for index in 0..<Self._bitWidth {
                let wire = scope.addXOR(of: lhsWires[index], and: rhsWires[index])
                joinWire = scope.addOR(of: wire, and: joinWire)
            }
            return !BoolRef(wireID: joinWire)
        }
    }

    @inlinable
    static func != (lhs: Self, rhs: Self) -> BoolRef {
        return !(lhs == rhs)
    }
}

public enum _WireRefTraverseType {
    case type(any WireRef.Type)
    case count
}

extension WireRef {
    @inlinable
    internal func _getAllWireIDs() -> [_WireID] {
        var wires: [_WireID] = []
        wires.reserveCapacity(Self._bitWidth)
        for index in 0..<Self._bitWidth {
            wires.append(_getBit(at: index))
        }
        return wires
    }

    public func _getBit(at index: Int) -> _WireID {
        var traverser = _SingleWireTraverser(index: index)
        _traverse(using: &traverser)
        return traverser.wire
    }
}

public extension WireRef {

    @usableFromInline
    internal init(from arr: consuming [_WireID]) {
        var builder = _ArrayWirePopper(array: arr)
        self.init(byPoppingBits: &builder)
    }

    init(byPortMapping scope: isolated _SynthScope, parentName: String?) {
        self.init(parentName: parentName) { name, bitWidth in
            scope.addInput(name: name, bitWidth: bitWidth)
        }
    }

    func _addResult(parentName: String?, to scope: isolated _SynthScope) {
        _applyPerPart(parentName: parentName) { name, part in
            scope.addResult(part, name: name)
        }
    }

    init(parentName: String?, body: (_ name: String, _ bitWidth: Int) -> [_WireID]) {
        let wires = body(parentName ?? "value", Self._bitWidth)
        self = .init(from: wires)
    }

    func _applyPerPart(parentName: String?, body: (_ name: String, _ part: [_WireID]) -> Void) {
        body(parentName ?? "value", _getAllWireIDs())
    }
}

public extension WireRef {
    func `as`<Target: WireRef>(_ type: Target.Type) -> Target {
        let wires = _getAllWireIDs()
        assert(type._bitWidth == wires.count)
        return .init(from: wires)
    }
}

@inlinable
public func _joinModuleName(base: String?, suffix: String, preferBase: Bool = false) -> String {
    if let base {
        if preferBase { return base }
        return "\(base)_\(suffix)"
    } else {
        return suffix
    }
}
