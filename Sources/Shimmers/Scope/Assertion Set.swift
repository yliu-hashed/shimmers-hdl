//
//  Shimmers/Scope/Assertion Set.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

/// Represents a set of assertions, including any custom assertions.
public enum AssertionSet: Sendable, ExpressibleByArrayLiteral, SetAlgebra {

    public typealias ArrayLiteralElement = AssertionType

    case including(set: Set<AssertionType>)
    case excluding(set: Set<AssertionType>)

    public static var empty: AssertionSet { .including(set: []) }
    public static var all: AssertionSet { .excluding(set: []) }

    public init() {
        self = .including(set: [])
    }

    public init(arrayLiteral elements: AssertionType...) {
        self = .including(set: Set(elements))
    }

    public typealias Element = AssertionType

    public func union(_ other: AssertionSet) -> AssertionSet {
        switch (self, other) {
        case (.including(let lhs), .including(let rhs)):
            return .including(set: lhs.union(rhs))
        case (.including(let lhs), .excluding(let rhs)):
            return .excluding(set: rhs.subtracting(lhs))
        case (.excluding(let lhs), .including(let rhs)):
            return .excluding(set: lhs.subtracting(rhs))
        case (.excluding(let lhs), .excluding(let rhs)):
            return .excluding(set: lhs.intersection(rhs))
        }
    }

    public func intersection(_ other: AssertionSet) -> AssertionSet {
        switch (self, other) {
        case (.including(let lhs), .including(let rhs)):
            return .including(set: lhs.intersection(rhs))
        case (.including(let lhs), .excluding(let rhs)):
            return .including(set: lhs.subtracting(rhs))
        case (.excluding(let lhs), .including(let rhs)):
            return .including(set: rhs.subtracting(lhs))
        case (.excluding(let lhs), .excluding(let rhs)):
            return .excluding(set: lhs.union(rhs))
        }
    }

    public var complement: AssertionSet {
        switch self {
        case .including(let set):
            return .excluding(set: set)
        case .excluding(let set):
            return .including(set: set)
        }
    }

    public func symmetricDifference(_ other: AssertionSet) -> AssertionSet {
        switch (self, other) {
        case (.including(let lhs), .including(let rhs)):
            return .including(set: lhs.symmetricDifference(rhs))
        case (.including(let lhs), .excluding(let rhs)):
            return .excluding(set: lhs.symmetricDifference(rhs))
        case (.excluding(let lhs), .including(let rhs)):
            return .excluding(set: lhs.symmetricDifference(rhs))
        case (.excluding(let lhs), .excluding(let rhs)):
            return .including(set: lhs.symmetricDifference(rhs))
        }
    }

    public mutating func formUnion(_ other: AssertionSet) {
        self = union(other)
    }

    public mutating func formIntersection(_ other: AssertionSet) {
        self = intersection(other)
    }

    public mutating func formSymmetricDifference(_ other: AssertionSet) {
        self = symmetricDifference(other)
    }

    public func contains(_ member: AssertionType) -> Bool {
        switch self {
        case .including(let set):
            set.contains(member)
        case .excluding(let set):
            !set.contains(member)
        }
    }

    public mutating func remove(_ member: AssertionType) -> AssertionType? {
        switch self {
        case .including(var set):
            let contained = set.contains(member)
            set.remove(member)
            self = .including(set: set)
            return contained ? member : nil
        case .excluding(var set):
            let contained = set.contains(member)
            set.update(with: member)
            self = .excluding(set: set)
            return contained ? nil : member
        }
    }

    public mutating func update(with newMember: AssertionType) -> AssertionType? {
        switch self {
        case .including(var set):
            let contained = set.contains(newMember)
            set.update(with: newMember)
            self = .including(set: set)
            return contained ? newMember : nil
        case .excluding(var set):
            let contained = set.contains(newMember)
            set.remove(newMember)
            self = .excluding(set: set)
            return contained ? nil : newMember
        }
    }

    public mutating func insert(_ newMember: AssertionType) -> (inserted: Bool, memberAfterInsert: AssertionType) {
        switch self {
        case .including(var set):
            let contained = set.contains(newMember)
            set.update(with: newMember)
            self = .including(set: set)
            return (!contained, newMember)
        case .excluding(var set):
            let contained = set.contains(newMember)
            set.remove(newMember)
            self = .excluding(set: set)
            return (contained, newMember)
        }
    }
}
