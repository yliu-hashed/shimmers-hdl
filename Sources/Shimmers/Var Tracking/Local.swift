//
//  Shimmers/Var Tracking/Local.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

@propertyWrapper
public struct _Local<Ref: WireRef>: Sendable {
    @usableFromInline
    internal let id: UInt32

    @inlinable
    public init(wrappedValue: Ref) {
        let id = _unsafeScopeIsolated { scope in
            scope.createVirtualID(for: Ref.self, initialValue: wrappedValue)
        }
        self.id = id
    }

    @inlinable
    public init() {
        let id = _unsafeScopeIsolated { scope in
            scope.createVirtualID(for: Ref.self, initialValue: nil)
        }
        self.id = id
    }

    @inlinable
    public var wrappedValue: Ref {
        get {
            return _unsafeScopeIsolated { scope in
                scope.getVirtual(id: id)
            }
        }
        set {
            _unsafeScopeIsolated { scope in
                scope.virtualChanged(id: id, to: newValue)
            }
        }
    }
}
