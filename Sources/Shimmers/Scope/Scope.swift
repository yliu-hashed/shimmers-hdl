//
//  Shimmers/Scope/Scope.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Foundation
import Subprocess
#if canImport(System)
@preconcurrency import System
#else
@preconcurrency import SystemPackage
#endif

public struct _WireID: Hashable, Equatable, ExpressibleByBooleanLiteral, Sendable {
    @usableFromInline
    internal var id: UInt32

    @inlinable
    internal init(id: UInt32) {
        self.id = id
    }

    @inlinable
    internal init(_ value: Bool) {
        id = value ? 1 : 0
    }

    @inlinable
    public init(booleanLiteral value: Bool) {
        id = value ? 1 : 0
    }

    @inlinable
    public static prefix func ! (rhs: Self) -> Self {
        return _WireID(id: rhs.id ^ 1)
    }

    @inlinable
    public var constant: Bool? {
        switch id {
        case 0:
            return false
        case 1:
            return true
        default:
            return nil
        }
    }
}

public final actor _SynthScope {
    internal let builder = GraphBuilder()
    public let name: String

    internal let moduleNamePrefix: String

    init(name: String, with options: SynthOptions) {
        self.name = name
        self.moduleNamePrefix = options.moduleNamePrefix
        self.enabledAssertions = options.disabledAssertions.complement

        switch options.kissat {
        case .none:
            kissatPath = nil
        case .inferFromPath:
            let exec = Executable.name("kissat")
            kissatPath = try? exec.resolveExecutablePath(in: .inherit)
        case .custom(let path):
            kissatPath = FilePath(path)
        }
    }

    private var lastVirtualID: UInt32 = 0
    internal func genVirtualID() -> UInt32 {
        precondition(lastVirtualID != .max, "Too much virtual id in scope")
        lastVirtualID += 1
        return lastVirtualID
    }

    private var lastLoopID: UInt64 = 0
    internal func genLoopID() -> UInt64 {
        lastLoopID += 1
        return lastLoopID
    }

    internal var debugRecorder = DebugRecorder()

    internal var currFrame = CondFrame()

    internal var cnfBuilder = CNFBuidler()

    internal var enabledAssertions: AssertionSet

    internal var kissatPath: FilePath?

    internal var messageManager: MessageManager = MessageManager()
    internal var localEncounteredError: Bool = false
    internal func didEncounteredErrors() -> Bool {
        return messageManager.didEncounteredErrors()
    }

    internal var pendingTasks: [Task<(),Never>] = []

    public func awaitAllPendingTasks() async -> [SynthMessage] {
        for task in pendingTasks {
            await task.value
        }
        pendingTasks.removeAll()
        return await messageManager.getAllMessages()
    }

    func emitVerilog(withIncludes: Bool) -> String {
        guard !didEncounteredErrors() else { return "Failed" }
        return builder.buildVerilog(namePrefix: moduleNamePrefix, name: name, printIncludes: withIncludes)
    }
}

/// An internal facility to access a ``Shimmers/_SynthScope`` and its isolation without waiting.
@inlinable
internal nonisolated func _unsafeScopeIsolated<T: Sendable>(_ operation: (isolated _SynthScope) -> T) -> T {
    typealias IsolatedClosure = (isolated _SynthScope) -> T
    typealias NonisolatedClosure = (_SynthScope) -> T

    let scope = _ScopeControl.currentScope!
    scope.assertIsolated()

    return withoutActuallyEscaping(operation) { (_ escaped: @escaping IsolatedClosure) -> T in
        let rawFn = unsafeBitCast(escaped, to: NonisolatedClosure.self)
        return rawFn(scope)
    }
}
