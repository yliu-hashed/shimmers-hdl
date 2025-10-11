//
//  Shimmers/Wire Types/Integers/IntRef - Literal.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension _UIntRefTemplate: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt.IntegerLiteralType

    public init(_ base: UInt) {
        self.wireIDs = (0..<Self._bitWidth).map { index in
            let bool = base & (1 << index) != 0
            return .init(bool)
        }
    }

    public init(integerLiteral value: IntegerLiteralType) {
        let base = UInt(integerLiteral: value)
        self.init(base)
    }
}

extension _SIntRefTemplate: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int.IntegerLiteralType

    public init(_ base: Int) {
        self.wireIDs = (0..<Self._bitWidth).map { index in
            let bool = base & (1 << index) != 0
            return .init(bool)
        }
    }

    public init(integerLiteral value: IntegerLiteralType) {
        let base = Int(integerLiteral: value)
        self.init(base)
    }
}
