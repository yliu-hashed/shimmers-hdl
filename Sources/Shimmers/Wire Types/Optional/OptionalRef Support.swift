//
//  Shimmers/Wire Types/Optional/OptionalRef Support.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//


public extension OptionalRef {
    func _chain<T: WireRef>(_ body: (WrappedRef) -> T) -> OptionalRef<T> {
        @_Local var result: OptionalRef<T> = .none
        _if(_isValid) {
            result = .some(body(wrapped))
        }
        return result
    }

    func _chain<T: WireRef>(_ body: (WrappedRef) -> OptionalRef<T>) -> OptionalRef<T> {
        @_Local var result: OptionalRef<T> = .none
        _if(_isValid) {
            let value = body(wrapped)
            _if(value._isValid) {
                result = .some(value.wrapped)
            }
        }
        return result
    }

    static func ?? (lhs: Self, rhs: @autoclosure () -> WrappedRef) -> WrappedRef {
        @_Local var result: WrappedRef = lhs._unchecked_unwraped
        _if(!lhs._isValid) {
            result = rhs()
        }
        return result
    }

    static func ?? (lhs: Self, rhs: @autoclosure () -> Self) -> Self {
        @_Local var result: Self = lhs
        _if(!lhs._isValid) {
            result = rhs()
        }
        return result
    }
}
