//
//  Shimmers/Runtime Support/BigInt/BigInt - Conversion & Literal.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension BigInt {
    typealias IntegerLiteralType = StaticBigInt

    init(integerLiteral value: StaticBigInt) {
        let wordCount = Int((value.bitWidth + UInt.bitWidth - 1) / UInt.bitWidth)
        segments = []
        segments.reserveCapacity(wordCount)
        for i in 0..<wordCount {
            segments.append(value[i])
        }
        let isNegative = (segments.last ?? 0) >= 1 << (UInt.bitWidth - 1)
        exten = isNegative ? .max : 0
        trim()
    }
}

extension BigInt {
    init?<T>(exactly source: T) where T : BinaryFloatingPoint {
        fatalError("\(#function) not implemented")
    }

    init<T>(_ source: T) where T : BinaryFloatingPoint {
        fatalError("\(#function) not implemented")
    }

    init<T>(truncatingIfNeeded source: T) where T : BinaryInteger {
        self.init(source)
    }

    init?<T>(exactly source: T) where T : BinaryInteger {
        self.init(source)
    }

    init<T>(clamping source: T) where T : BinaryInteger {
        self.init(source)
    }

    init<T>(_ source: T) where T : BinaryInteger {
        segments = [UInt](source.words)
        let isNegative = (segments.last ?? 0) >= 1 << (UInt.bitWidth - 1)
        exten = isNegative ? .max : 0
        trim()
    }
}
