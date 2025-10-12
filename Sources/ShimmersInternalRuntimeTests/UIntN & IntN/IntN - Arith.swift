//
//  ShimmersInternalRuntimeTests/UIntN & IntN/IntN - Arith.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "IntN Arithmetics",
    .tags(
        .ShimmersInternalTests_Runtime.StandardLibrary.integers,
    )
)
struct IntNArithmeticsTestSuite {
    let vals: [IntN<8>] = [0, 1, -1, 2, -3, 12, 16, -17, 29, -123, 127, -127, -128]
    let refs: [Int8   ] = [0, 1, -1, 2, -3, 12, 16, -17, 29, -123, 127, -127, -128]
    let count = 13

    @Test func intN_conversions() async throws {
        for i in 0..<count {
            let result = vals[i]
            let truth  = refs[i]
            #expect(result == truth)
        }
    }

    @Test func intN_add() async throws {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i].addingReportingOverflow(vals[j])
                let truth  = refs[i].addingReportingOverflow(refs[j])
                let name: Comment = "\(refs[i]) + \(refs[j])"
                #expect(result.partialValue == truth.partialValue, name)
                #expect(result.overflow == truth.overflow, name)
            }
        }
    }

    @Test func intN_sub() async throws {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i].subtractingReportingOverflow(vals[j])
                let truth  = refs[i].subtractingReportingOverflow(refs[j])
                let name: Comment = "\(refs[i]) + \(refs[j])"
                #expect(result.partialValue == truth.partialValue, name)
                #expect(result.overflow == truth.overflow, name)
            }
        }
    }

    @Test func intN_mul() async throws {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i].multipliedReportingOverflow(by: vals[j])
                let truth  = refs[i].multipliedReportingOverflow(by: refs[j])
                let name: Comment = "\(refs[i]) + \(refs[j])"
                #expect(result.partialValue == truth.partialValue, name)
                #expect(result.overflow == truth.overflow, name)
            }
        }
    }

    @Test func intN_div() async throws {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i].dividedReportingOverflow(by: vals[j])
                let truth  = refs[i].dividedReportingOverflow(by: refs[j])
                let name: Comment = "\(refs[i]) + \(refs[j])"
                #expect(result.partialValue == truth.partialValue, name)
                #expect(result.overflow == truth.overflow, name)
            }
        }
    }

    @Test func intN_rem() async throws {
        for i in 0..<count {
            for j in 0..<count {
                let result = vals[i].remainderReportingOverflow(dividingBy: vals[j])
                let truth  = refs[i].remainderReportingOverflow(dividingBy: refs[j])
                let name: Comment = "\(refs[i]) % \(refs[j])"
                #expect(result.partialValue == truth.partialValue, name)
                #expect(result.overflow == truth.overflow, name)
            }
        }
    }
}
