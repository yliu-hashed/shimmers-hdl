//
//  Shimmers/Wire Types/Enum Support/Enum Wire Type.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public protocol _EnumWireRef: WireRef {
    func _unbind(name: String, index: Int) -> any Shimmers.WireRef
    func _unbind_is(name: String) -> BoolRef
}
