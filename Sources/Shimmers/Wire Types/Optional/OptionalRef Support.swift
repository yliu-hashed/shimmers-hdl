//
//  Shimmers/Wire Types/Optional/OptionalRef Support.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

//public enum OptionalPromoteMode {
//    case normal
//}
//
//public protocol SomeOptionalSynthRef: WireRef {
//    associatedtype DeepWrappedRef: WireRef
//}
//
//extension WireRef {
//    public subscript (_p mode: OptionalPromoteMode) -> Self {
//        get {
//            return self
//        }
//        set {
//            self = newValue
//        }
//    }
//
//    public subscript (_p mode: OptionalPromoteMode) -> OptionalSynthRef<Self> {
//        get {
//            let scope = _ScopeControl.currentScope!
//            return .init(validID: 1, wrapped: self, in: scope)
//        }
//    }
//}

public extension OptionalRef {
    func _chain<T: WireRef>(_ body: (WrappedRef) -> T) -> OptionalRef<T> {
        @_Local var result: OptionalRef<T>
        _if(_isValid) {
            result = .some(body(wrapped))
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
