//
//  Shimmers/Var Tracking/Member.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

@propertyWrapper
public struct _Member<Ref: WireRef>: Sendable {
    @usableFromInline
    internal var storage: Storage

    private var level: Int = 0

    @usableFromInline
    internal enum Storage: Sendable {
        case virtual(id: UInt32)
        indirect case concrete(ref: Ref!)
    }

    @inlinable
    public init(wrappedValue: Ref) {
        storage = .concrete(ref: wrappedValue)
    }

    @inlinable
    public init() {
        storage = .concrete(ref: nil)
    }

    @inlinable
    public var wrappedValue: Ref {
        get {
            switch storage {
            case .concrete(ref: let ref):
                return ref!
            case .virtual(id: let id):
                return _unsafeScopeIsolated { scope in
                    return scope.getVirtual(id: id)
                }
            }
        }
        set {
            guard case .virtual(let id) = storage else {
                storage = .concrete(ref: newValue)
                return
            }
            _unsafeScopeIsolated { scope in
                scope.virtualChanged(id: id, to: newValue)
            }
        }
    }

    public mutating func virtualize() {
        level += 1
        guard level == 1 else { return }
        guard case .concrete(let local) = storage else { fatalError() }
        let id = _unsafeScopeIsolated { scope in
            scope.createVirtualID(for: Ref.self, initialValue: local)
        }
        storage = .virtual(id: id)
    }

    public mutating func devirtualize() {
        level -= 1
        guard level == 0 else { return }
        guard case .virtual(let id) = storage else { fatalError() }
        let detached: Ref = _unsafeScopeIsolated { scope in
            scope.detachVirtual(id)
        }
        storage = .concrete(ref: detached)
    }
}
