//
//  ShimmersInternalLogicTests/Inline Array/Inline Array Access.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Testing
import Shimmers

@HardwareWire
fileprivate struct ArrayIndexGet {
    var result: UInt8

    static func get(index: Int) -> Self {
        let arr: InlineArray<8, UInt8> = [1, 3, 7, 22, 34, 99, 123, 234]
        let value = arr[index]
        return .init(result: value)
    }
}

@HardwareWire
fileprivate struct ArrayIndexSet {
    var result: InlineArray<8, UInt8>

    static func set(index: Int, value: UInt8) -> Self {
        var arr: InlineArray<8, UInt8> = [1, 3, 7, 22, 34, 99, 123, 234]
        arr[index] = value
        return .init(result: arr)
    }
}

@HardwareWire
fileprivate struct ArrayIndexSwap {
    var result: InlineArray<8, UInt8>

    static func swap(indexA: Int, indexB: Int) -> Self {
        var arr: InlineArray<8, UInt8> = [1, 3, 7, 22, 34, 99, 123, 234]
        arr.swapAt(indexA, indexB)
        return .init(result: arr)
    }
}

@Suite(
    "Inline Array Access",
    .tags(
        .ShimmersInternalTests_Logic.StandardLibrary.core,
    )
)
struct InlineArrayAccessTestSuite {
    @Test func index_get() async {
        let network = await dumpSimpleNetwork(of: ArrayIndexGetRef.get)

        func sim(_ index: Int) -> UInt8 {
            let inputs: [String: UInt64] = [
                "0": UInt64(index)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            return UInt8(truncatingIfNeeded: outputs["result"]!)
        }

        #expect(sim(0) ==   1)
        #expect(sim(1) ==   3)
        #expect(sim(2) ==   7)
        #expect(sim(3) ==  22)
        #expect(sim(4) ==  34)
        #expect(sim(5) ==  99)
        #expect(sim(6) == 123)
        #expect(sim(7) == 234)
    }

    @Test func index_set() async {
        let network = await dumpSimpleNetwork(of: ArrayIndexSetRef.set)

        func sim(_ index: Int, _ value: UInt8) -> [UInt8] {
            let inputs: [String: UInt64] = [
                "0": UInt64(index),
                "1": UInt64(value)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            var array = [UInt8](repeating: 0, count: 8)
            for i in 0..<8 {
                array[i] = UInt8(truncatingIfNeeded: outputs["result_\(i)"]!)
            }
            return array
        }

        let testValues: [UInt8] = [2, 61, 221, 255]
        for i in 0..<8 {
            for value in testValues {
                var correct: [UInt8] = [1, 3, 7, 22, 34, 99, 123, 234]
                correct[i] = value
                #expect(sim(i, value) == correct, "arr\(i) = \(value)")
            }
        }
    }

    @Test func index_swap() async {
        let network = await dumpSimpleNetwork(of: ArrayIndexSwapRef.swap)

        func sim(_ indexA: Int, _ indexB: Int) -> [UInt8] {
            let inputs: [String: UInt64] = [
                "0": UInt64(indexA),
                "1": UInt64(indexB)
            ]
            let outputs = simulate(network: network, inputs: inputs)
            var array = [UInt8](repeating: 0, count: 8)
            for i in 0..<8 {
                array[i] = UInt8(truncatingIfNeeded: outputs["result_\(i)"]!)
            }
            return array
        }

        for i in 0..<8 {
            for j in 0..<8 {
                var correct: [UInt8] = [1, 3, 7, 22, 34, 99, 123, 234]
                correct.swapAt(i, j)
                #expect(sim(i, j) == correct, "swapAt(\(i), \(j))")
            }
        }
    }
}
