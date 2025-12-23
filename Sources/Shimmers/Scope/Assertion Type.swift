//
//  Shimmers/Scope/Assertion Type.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

/// A target for formal verification
public enum AssertionType: Sendable, Hashable, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    /// Formal targets for array bound checks.
    case bound
    /// Formal targets for overflowable conversions like `UInt8(12345)`.
    case overflowConvert
    /// Formal targets for arithmetic operations like the integer `+` operator
    case overflowMath
    /// Formal targets that validates that the ``assume(_:type:_:)`` macro is not contradictory
    case assumption
    /// The default type of the ``assert(_:type:_:)`` macro.
    case assert
    /// The default type of the ``never(type:_:)`` macro.
    case never
    /// A custom assertion created using a string literal.
    case custom(name: String)

    /// All cases of ``AssertionType`` excluding any custom values.
    public static let builtinValues: [AssertionType] = [
        .bound,
        .overflowConvert,
        .overflowMath,
        .assumption,
        .assert,
        .never,
    ]

    @inlinable
    public init(stringLiteral value: String) {
        self.init(name: value)
    }

    /// Create a ``AssertionType`` by using its name
    public init(name: String) {
        switch name {
        case "bound":
            self = .bound
        case "overflowConvert":
            self = .overflowConvert
        case "overflowMath":
            self = .overflowMath
        case "assert":
            self = .assert
        case "assumption":
            self = .assumption
        default: self = .custom(name: name)
        }
    }

    /// The name represented by an assertion type
    public var name: String {
        switch self {
        case .bound:
            return "bound"
        case .overflowConvert:
            return "overflowConvert"
        case .overflowMath:
            return "overflowMath"
        case .assert:
            return "assert"
        case .assumption:
            return "assumption"
        case .never:
            return "never"
        case .custom(let name):
            return name
        }
    }
}
