//
//  Shimmers/Wire Types/Ternary.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

infix operator ><?>< : _TerneryConvertPrecedence
infix operator ><|>< : TernaryPrecedence

precedencegroup _TerneryConvertPrecedence {
    associativity : right
    higherThan    : TernaryPrecedence
    lowerThan     : LogicalDisjunctionPrecedence
}

public struct _TernaryConvertLHSPartial<R: WireRef>: Sendable {
    fileprivate var first: R
    fileprivate var doFirst: BoolRef
}

public func ><?>< <R: WireRef> (lhs: BoolRef, rhs: @autoclosure () -> R) -> _TernaryConvertLHSPartial<R> {
    var builder = _ZeroWirePopper()
    @_Local var first: R = R(_byPoppingBits: &builder)
    _if(lhs) {
        first = rhs()
    }
    return _TernaryConvertLHSPartial(first: first, doFirst: lhs)
}


public func ><|>< <R: WireRef> (lhs: _TernaryConvertLHSPartial<R>, rhs: @autoclosure () -> R) -> R {
    var builder = _ZeroWirePopper()
    @_Local var second: R = R(_byPoppingBits: &builder)
    _if(!lhs.doFirst) {
        second = rhs()
    }
    let falseArgs = second._getAllWireIDs()
    return _unsafeScopeIsolated { scope in
        let bits = scope.buildMux(cond: lhs.doFirst.wireID, lhs: lhs.first._getAllWireIDs(), rhs: falseArgs)
        return R(from: bits)
    }
}
