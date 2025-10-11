//
//  Shimmers/Wire Types/Pattern Matching/Pattern Matching.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

private extension WireRef {
    func exactlyMatches(_ other: any WireRef) -> BoolRef {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}

public struct _MultiPattern {

    var patterns: [_Pattern]
    public init(patterns: [_Pattern]) {
        self.patterns = patterns
    }

    public func match(_ value: any WireRef) -> Result {
        @_Local var isMatch: BoolRef = false
        var results: [(enable: BoolRef, results: [String: any WireRef])] = []
        for pattern in patterns {
            let result = pattern.match(value)
            results.append((enable: !isMatch && result.isMatch, results: result.results))
            _if(result.isMatch) {
                isMatch = true
            }
        }
        return Result(isMatch: isMatch, results: results)
    }

    public struct Result: Sendable {
        public var isMatch: BoolRef
        var results: [(enable: BoolRef, results: [String: any WireRef])]

        public func get<V: WireRef, W: WireRef>(_ name: String, of host: W, with paths: [KeyPath<W, V>]) -> V {
            return _unsafeScopeIsolated { scope in
                var wires = [_WireID](repeating: false, count: V._bitWidth)
                for (enable, results) in results {
                    let result = results[name] as! V
                    for (i, wire) in result._getAllWireIDs().enumerated() {
                        wires[i] = scope.addOR(of: wires[i], and: scope.addAND(of: wire, and: enable.wireID))
                    }
                }
                return V(from: wires)
            }
        }
    }
}

public enum _Pattern {
    case value(any WireRef)
    case wildcard
    case function(name: String, args: [_Pattern])
    case member(name: String)
    case identifier(name: String)

    public func match(_ value: any WireRef) -> Result {
        switch self {
        case .value(let expectedValue):
            let isMatch = value.exactlyMatches(expectedValue)
            return Result(isMatch: isMatch)
        case .wildcard:
            return Result(isMatch: true)
        case .member(let name):
            guard let enumeration = value as? any _EnumWireRef else {
                return Result(isMatch: false)
            }
            let isMatch = enumeration._unbind_is(name: name)
            return Result(isMatch: isMatch)
        case .function(let name, let args):
            guard let enumeration = value as? any _EnumWireRef else {
                fatalError("Attempting to decompose a non-enumeration value")
            }
            @_Local var isMatch: BoolRef = false
            var matches: [String: any WireRef] = [:]
            _if(enumeration._unbind_is(name: name), alwaysSynth: true) {
                isMatch = true
                for (index, arg) in args.enumerated() {
                    let unbind = enumeration._unbind(name: name, index: index)
                    let result = arg.match(unbind)
                    isMatch = isMatch && result.isMatch
                    matches.merge(result.results) { _,_ in
                        fatalError("Declaring two values with the same name in a function pattern is not supported")
                    }
                }
            }
            return Result(isMatch: isMatch, results: matches)
        case .identifier(let name):
            return Result(isMatch: true, results: [name: value])
        }
    }

    public struct Result: Sendable {
        public var isMatch: BoolRef
        var results: [String: any WireRef]

        fileprivate init(isMatch: BoolRef, results: [String: any WireRef] = [:]) {
            self.isMatch = isMatch
            self.results = results
        }

        public func get<V: WireRef, W: WireRef>(_ name: String, of host: W, with paths: KeyPath<W, V>) -> V {
            return results[name] as! V
        }
    }

    @inlinable
    public static func value<V: WireRef, W: WireRef>(_ value: V, of host: W, with path: KeyPath<W, V>) -> _Pattern {
        .value(value)
    }

    @inlinable
    public static func value<W: WireRef>(_ value: W, matching host: W) -> _Pattern {
        .value(value)
    }
}

