//
//  Shimmers/Mangle/Hashing.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension String {
    /// Use DJB2 hash to deterministically hash a string
    var djb2HashValue: UInt32 {
        var hash: UInt32 = 5381
        for byte in utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt32(byte)
        }
        return hash
    }
}
