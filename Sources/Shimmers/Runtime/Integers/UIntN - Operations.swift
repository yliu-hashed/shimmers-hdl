//
//  Shimmers/Runtime/Integers/UIntN - Operations.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public extension UIntN {
    static func ^= (lhs: inout UIntN<__bitWidth>, rhs: UIntN<__bitWidth>) {
        lhs.value ^= rhs.value
    }

    static func |= (lhs: inout Self, rhs: Self) {
        lhs.value |= rhs.value
    }

    static func &= (lhs: inout Self, rhs: Self) {
        lhs.value &= rhs.value
    }

    static func & (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result &= rhs
        return result
    }

    static func | (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result |= rhs
        return result
    }

    static func ^ (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result ^= rhs
        return result
    }

    static prefix func ~ (rhs: Self) -> Self {
        return .init(value: ~rhs.value)
    }

    static func &<<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        lhs.value <<= rhs
        lhs.value.truncatingUnsigned(to: Self.bitWidth)
    }

    static func &>>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        lhs.value >>= rhs
    }

    var trailingZeroBitCount: Int {
        let result = value.trailingZeroBitCount
        return result > Self.bitWidth ? Self.bitWidth : result
    }

    var nonzeroBitCount: Int {
        var result = 0
        for i in 0..<Self.bitWidth {
            if value.getBit(at: i) {
                result += 1
            }
        }
        return result
    }

    var leadingZeroBitCount: Int {
        var result = 0
        for i in (0..<Self.bitWidth).reversed() {
            guard !value.getBit(at: i) else { break }
            result += 1
        }
        return result
    }
}

public extension UIntN {
    func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        var result = value + rhs.value
        if result > Self.bigMax {
            result.truncatingUnsigned(to: Self.bitWidth)
            return (.init(value: result), true)
        }
        return (.init(value: result), false)
    }

    func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        var result = value - rhs.value
        if result < 0 {
            result.truncatingUnsigned(to: Self.bitWidth)
            return (.init(value: result), true)
        }
        return (.init(value: result), false)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        precondition(!overflow)
        return result
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.subtractingReportingOverflow(rhs)
        precondition(!overflow)
        return result
    }
}

public extension UIntN {
    func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        var result = value * rhs.value
        if result > Self.bigMax {
            result.truncatingUnsigned(to: Self.bitWidth)
            return (.init(value: result), true)
        }
        return (.init(value: result), false)
    }

    func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs == 0 { return (self, true) }
        let result = value / rhs.value
        return (.init(value: result), false)
    }

    func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs == 0 { return (self, true) }
        let result = value % rhs.value
        return (.init(value: result), false)
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        precondition(!overflow)
        return result
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.dividedReportingOverflow(by: rhs)
        precondition(!overflow)
        return result
    }

    static func % (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.remainderReportingOverflow(dividingBy: rhs)
        precondition(!overflow)
        return result
    }

    static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }

    static func %= (lhs: inout Self, rhs: Self) {
        lhs = lhs % rhs
    }
}
