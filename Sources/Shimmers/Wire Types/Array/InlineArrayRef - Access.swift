//
//  Shimmers/Wire Types/Array/InlineArrayRef - Access.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public extension InlineArrayRef {
    typealias ElementRef = ElementRef
    typealias IndexRef = IntRef

    @inlinable
    var startIndex: IntRef {
        return 0
    }

    @inlinable
    var endIndex: IntRef {
        return IntRef(count)
    }

    @inlinable
    var indices: RangeRef<IntRef> {
        return RangeRef(lowerBound: startIndex, upperBound: endIndex)
    }

    subscript (index: IntRef) -> ElementRef {
        get {
            _proveAssert(index >= 0 && index < .init(count), type: .bound)
            return downMUX(storage, at: index)
        }
        set {
            _proveAssert(index >= 0 && index < .init(count), type: .bound)
            for i in 0..<count {
                @_Local var value = storage[i]
                _if(index == .init(i)) {
                    value = newValue
                }
                storage[i] = value
            }
        }
    }

    subscript (index: some BinaryIntegerRef & FixedWidthIntegerRef) -> ElementRef {
        get {
            let i = IntRef(index)
            return self[i]
        }
        set {
            let i = IntRef(index)
            self[i] = newValue
        }
    }

    mutating func swapAt(_ i: IntRef, _ j: IntRef) {
        let elementI = downMUX(storage, at: i)
        let elementJ = downMUX(storage, at: j)
        for index in 0..<count {
            @_Local var value = storage[index]
            _if(i == .init(index)) {
                value = elementJ
            }
            _if(j == .init(index)) {
                value = elementI
            }
            storage[index] = value
        }
    }
}
