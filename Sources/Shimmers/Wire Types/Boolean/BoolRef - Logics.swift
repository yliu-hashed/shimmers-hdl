//
//  Shimmers/Wire Types/Boolean/BoolRef - Logics.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension BoolRef: EquatableRef {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Self {
        return _unsafeScopeIsolated { scope in
            let newWire = scope.addXOR(of: lhs.wireID, and: rhs.wireID)
            return Self(wireID: !newWire)
        }
    }

    @inlinable
    public static func != (lhs: Self, rhs: Self) -> Self {
        return !(lhs == rhs)
    }
}

public extension BoolRef {
    @inlinable
    internal func _mux<T: WireRef>(_ lhs: T, else rhs: T) -> T {
        let wires = _unsafeScopeIsolated { scope in
            scope.buildMux(cond: wireID, lhs: lhs._getAllWireIDs(), rhs: rhs._getAllWireIDs())
        }
        return T(from: wires)
    }

    @inlinable
    internal func _plainOR(with rhs: Self) -> Self {
        return _unsafeScopeIsolated { scope in
            let newWire = scope.addOR(of: wireID, and: rhs.wireID)
            return Self(wireID: newWire)
        }
    }

    @inlinable
    internal func _plainAND(with rhs: Self) -> Self {
        return _unsafeScopeIsolated { scope in
            let newWire = scope.addAND(of: wireID, and: rhs.wireID)
            return Self(wireID: newWire)
        }
    }

    @inlinable
    static func && (lhs: Self, rhs: @autoclosure () -> Self) -> Self {
        @_Local var rhsWire: Self = false
        _if(lhs) {
            rhsWire = rhs()
        }
        return lhs._plainAND(with: rhsWire)
    }

    @inlinable
    static func || (lhs: Self, rhs: @autoclosure () -> Self) -> Self {
        @_Local var rhsWire: Self = true
        _if(!lhs) {
            rhsWire = rhs()
        }
        return lhs._plainOR(with: rhsWire)
    }

    @inlinable
    static prefix func ! (rhs: Self) -> Self {
        return Self(wireID: !rhs.wireID)
    }

    @inlinable
    func implies(_ other: @autoclosure () -> Self) -> Self {
        return !self || other()
    }

    @inlinable
    func isImplied(by other: @autoclosure () -> Self) -> Self {
        return self || !other()
    }
}
