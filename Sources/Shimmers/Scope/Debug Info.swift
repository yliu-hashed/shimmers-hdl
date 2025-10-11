//
//  Shimmers/Scope/Debug Info.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

/// A location in the source code.
public struct DebugLocation: Sendable, CustomStringConvertible {
    public var file: StaticString
    public var line: UInt

    /// The file location to use when no location is available.
    public static var unknown: Self {
        Self(file: "unknown", line: 0)
    }

    public init(file: StaticString = #file, line: UInt = #line) {
        self.file = file
        self.line = line
    }

    public var description: String {
        return "\(file):\(line)"
    }
}

/// Represents a function in the middle of synthesis.
public struct DebugFrame: Sendable {
    /// The location of execution.
    public var lastDebugLoc: DebugLocation
    /// The name of the function in this frame.
    public var function: StaticString
}
