//
//  ShimmersInternalRuntimeTests/Test Tags.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing

extension Tag {
    enum ShimmersInternalTests_Runtime {}
}

extension Tag.ShimmersInternalTests_Runtime {
    enum Support {}
    enum StandardLibrary {}
}

extension Tag.ShimmersInternalTests_Runtime.Support {
    @Tag static var bigInteger: Tag
}

extension Tag.ShimmersInternalTests_Runtime.StandardLibrary {
    @Tag static var integers: Tag
}
