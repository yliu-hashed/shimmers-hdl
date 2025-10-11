//
//  Shimmers/Module.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol TopLevelGenerator: SendableMetatype {
    static var name: String { get }
    static func _generate() -> _WaitableSynthJob
}
