//
//  ShimmersInternalLogicTests/Test Tags.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing

extension Tag {
    enum ShimmersInternalTests_Logic {}
}

extension Tag.ShimmersInternalTests_Logic {
    enum MacroExpansion {}
    enum StandardLibrary {}
    enum Facility {}
}

extension Tag.ShimmersInternalTests_Logic.MacroExpansion {
    @Tag static var codeblock_if: Tag
    @Tag static var codeblock_guard: Tag
    @Tag static var codeblock_switch: Tag

    @Tag static var wire_enum: Tag
    @Tag static var wire_struct: Tag
}

extension Tag.ShimmersInternalTests_Logic.StandardLibrary {
    @Tag static var core: Tag
    @Tag static var extras: Tag
}

extension Tag.ShimmersInternalTests_Logic.Facility {
    @Tag static var verilog: Tag
}
