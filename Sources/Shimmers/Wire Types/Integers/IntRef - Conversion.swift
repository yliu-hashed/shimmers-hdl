//
//  Shimmers/Wire Types/Integers/IntRef - Conversion.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension _IntegerRefTemplate {
    public init<T>(clamping source: T) where T : BinaryIntegerRef {
        @_Local var result: Self = Self(truncatingIfNeeded: source)
        _if(source > Self.max) {
            result = Self.max
        }
        _if(source < Self.min) {
            result = Self.min
        }
        self = result
    }
}

extension _SIntRefTemplate {
    public init(bitPattern source: _UIntRefTemplate<__bitWidth>) {
        self.init(wireIDs: source.wireIDs)
    }
}

extension _UIntRefTemplate {
    public init(bitPattern source: _SIntRefTemplate<__bitWidth>) {
        self.init(wireIDs: source.wireIDs)
    }
}
