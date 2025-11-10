//
//  Shimmers/Wire Types/Integers/IntRef.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public typealias UIntRef   = _UIntRefTemplate< 64 >
public typealias UInt8Ref  = _UIntRefTemplate<  8 >
public typealias UInt16Ref = _UIntRefTemplate< 16 >
public typealias UInt32Ref = _UIntRefTemplate< 32 >
public typealias UInt64Ref = _UIntRefTemplate< 64 >

public typealias IntRef   = _SIntRefTemplate< 64 >
public typealias Int8Ref  = _SIntRefTemplate<  8 >
public typealias Int16Ref = _SIntRefTemplate< 16 >
public typealias Int32Ref = _SIntRefTemplate< 32 >
public typealias Int64Ref = _SIntRefTemplate< 64 >

public typealias  IntNRef = _SIntRefTemplate
public typealias UIntNRef = _UIntRefTemplate

public protocol _IntegerRefTemplate: FixedWidthIntegerRef, BinaryIntegerRef, NumericRef {
}

public struct _SIntRefTemplate<let __bitWidth: Int>: SignedIntegerRef, _IntegerRefTemplate {

    public typealias MagnitudeRef = _UIntRefTemplate<__bitWidth>
    public typealias StrideRef = IntRef

    @inlinable
    public static var _bitWidth: Int { __bitWidth }

    @inlinable
    public static var bitWidth: IntRef {
        return IntRef(_bitWidth)
    }

    @usableFromInline
    internal var wireIDs: [_WireID]

    @inlinable
    public func _getAllWireIDs() -> [_WireID] {
        wireIDs
    }

    @inlinable
    public func _getBit(at index: Int) -> _WireID {
        wireIDs[index]
    }

    @inlinable
    public func _traverse(using traverser: inout some _WireTraverser) {
        for wire in wireIDs {
            traverser.visit(wire: wire)
        }
    }

    internal init(wireIDs: consuming [_WireID]) {
        self.wireIDs = wireIDs
    }

    public init(_byPoppingBits builder: inout some _WirePopper) {
        self.wireIDs = (0..<Self._bitWidth).map { _ in builder.pop() }
    }
}

public struct _UIntRefTemplate<let __bitWidth: Int>: UnsignedIntegerRef, _IntegerRefTemplate {

    public typealias MagnitudeRef = _UIntRefTemplate<__bitWidth>
    public typealias StrideRef = IntRef

    @inlinable
    public static var _bitWidth: Int { __bitWidth }

    @inlinable
    public static var bitWidth: IntRef {
        return IntRef(_bitWidth)
    }

    @usableFromInline
    internal var wireIDs: [_WireID]

    @inlinable
    public func _getAllWireIDs() -> [_WireID] {
        wireIDs
    }

    @inlinable
    public func _getBit(at index: Int) -> _WireID {
        wireIDs[index]
    }

    @inlinable
    public func _traverse(using traverser: inout some _WireTraverser) {
        for wire in wireIDs {
            traverser.visit(wire: wire)
        }
    }

    internal init(wireIDs: consuming [_WireID]) {
        self.wireIDs = wireIDs
    }

    public init(_byPoppingBits builder: inout some _WirePopper) {
        self.wireIDs = (0..<Self._bitWidth).map { _ in builder.pop() }
    }
}
