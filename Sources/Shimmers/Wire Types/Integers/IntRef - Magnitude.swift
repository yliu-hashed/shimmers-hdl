//
//  Shimmers/Wire Types/Integers/IntRef - Magnitude.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public extension _SIntRefTemplate {
    var magnitude: MagnitudeRef {
        @_Local var result = MagnitudeRef(bitPattern: self)
        _if(self < 0) {
            result = 0 &- MagnitudeRef(bitPattern: self)
        }
        return result
    }
}
