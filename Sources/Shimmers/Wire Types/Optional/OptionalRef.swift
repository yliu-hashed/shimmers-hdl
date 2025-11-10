//
//  Shimmers/Wire Types/Optional/OptionalRef.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public struct OptionalRef<WrappedRef: WireRef>: WireRef, ExpressibleByNilLiteral {

    @inlinable
    public static var _bitWidth: Int { WrappedRef._bitWidth + 1 }

    internal var isValid: BoolRef
    internal var wrapped: WrappedRef

    public func _getBit(at index: Int) -> _WireID {
        if index == 0 {
            return isValid.wireID
        } else {
            return wrapped._getBit(at: index - 1)
        }
    }

    @usableFromInline
    internal init(isValid: BoolRef = true, wrapped: WrappedRef) {
        self.isValid = isValid
        self.wrapped = wrapped
    }

    public func _traverse(using traverser: inout some _WireTraverser) {
        traverser.visit(wire: isValid.wireID)
        if traverser.skip(width: WrappedRef._bitWidth) { return }
        wrapped._traverse(using: &traverser)
    }

    public init(_byPoppingBits builder: inout some _WirePopper) {
        isValid = BoolRef(_byPoppingBits: &builder)
        wrapped = WrappedRef(_byPoppingBits: &builder)
    }

    public init(_byPartWith parentName: String?, body: (_ name: String, _ bitWidth: Int) -> [_WireID]) {
        let validName = _joinModuleName(base: parentName, suffix: "valid")
        let wrappedName = _joinModuleName(base: parentName, suffix: "value")
        isValid = BoolRef(_byPartWith: validName, body: body)
        wrapped = WrappedRef(_byPartWith: wrappedName, body: body)
    }

    public func _applyPerPart(parentName: String?, body: (_ name: String, _ part: [_WireID]) -> Void) {
        isValid._applyPerPart(parentName: _joinModuleName(base: parentName, suffix: "valid"), body: body)
        wrapped._applyPerPart(parentName: _joinModuleName(base: parentName, suffix: "value"), body: body)
    }

    public init(nilLiteral: Void) {
        isValid = false
        var builder = _ZeroWirePopper()
        wrapped = .init(_byPoppingBits: &builder)
    }

    public var _unchecked_unwraped: WrappedRef {
        return wrapped
    }

    public var _checked_unwraped: WrappedRef {
        return _unsafeScopeIsolated { scope in
            scope.proveAssert(_isValid, type: .bound, msg: "Unwrap nil optional")
            return wrapped
        }
    }

    public var _isValid: BoolRef {
        return isValid
    }

    public static func some(_ value: WrappedRef) -> Self {
        return .init(wrapped: value)
    }
}

extension OptionalRef: EquatableRef where WrappedRef: EquatableRef {
    public static func == (lhs: Self, rhs: Self) -> BoolRef {
        @_Local var result: BoolRef = lhs.isValid == rhs.isValid
        _if(lhs.isValid && rhs.isValid) {
            result = lhs.wrapped == rhs.wrapped
        }
        return result
    }

    public static func != (lhs: Self, rhs: Self) -> BoolRef {
        return !(lhs == rhs)
    }
}
