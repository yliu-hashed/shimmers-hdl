//
//  ShimmersInternalRuntimeTests/UIntN & IntN/UIntN - Arith.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
@testable import Shimmers

@Suite(
    "UIntN Arithmetics",
    .tags(
        .ShimmersInternalTests_Runtime.StandardLibrary.integers,
    )
)
struct UIntNArithmeticsTestSuite {
    let vals: [UIntN<8>] = [0, 1, 2, 3, 12, 16, 17, 29, 123, 127, 128, 234, 255]
    let refs: [UInt8   ] = [0, 1, 2, 3, 12, 16, 17, 29, 123, 127, 128, 234, 255]
    let count = 13

    @Test func uIntN_add() async {
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

    @Test func uIntN_sub() async {
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

    @Test func uIntN_mul() async {
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

    @Test func uIntN_div() async {
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

    @Test func uIntN_rem() async {
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
