//
//  Shimmers/Scope/Scope - Debugging.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Synchronization

extension _SynthScope {
    public func getAllMessages() async -> [SynthMessage] {
        return await messageManager.getAllMessages()
    }
}

/// A message generated during synthesis.
public struct SynthMessage: Sendable, CustomStringConvertible {
    /// The associated source code location of the message.
    public var debugLoc: DebugLocation
    /// The stack frames that start from a detached or top-level function, and lead to the location of the message.
    public var frames: [DebugFrame]
    public var type: Kind
    public var message: String

    public enum Kind: Sendable {
        case info
        case error
        case warning

        internal var prefix: String {
            switch self {
            case .info:
                return "[INFO]"
            case .error:
                return "[ERROR]"
            case .warning:
                return "[WARNING]"
            }
        }
    }

    internal init(
        at debugLoc: consuming DebugLocation,
        in frames: consuming [DebugFrame],
        type: Kind, message: String
    ) {
        self.debugLoc = debugLoc
        self.frames = frames
        self.type = type
        self.message = message
    }

    public var description: String {
        return "\(type.prefix) \(debugLoc) \(message)"
    }
}

struct MessageManager {
    let async = AsyncMessageManager()
    private var localEncounteredError: Bool = false
    private var localMessages: [(id: UInt32, message: SynthMessage)] = []

    mutating func didEncounteredErrors() -> Bool {
        if localEncounteredError { return true }
        let encountered = async.hasError || localEncounteredError
        localEncounteredError = encountered
        return encountered
    }

    mutating func add(
        at debugLoc: consuming DebugLocation,
        in frames: [DebugFrame],
        type: SynthMessage.Kind,
        _ message: String
    ) {
        let id = reserveMessageID()
        if type == .error {
            localEncounteredError = true
        }
        let message = SynthMessage(at: debugLoc, in: frames, type: type, message: message)
        localMessages.append((id, message))
    }

    private var messageID: UInt32 = 0
    internal mutating func reserveMessageID() -> UInt32 {
        messageID += 1
        return messageID
    }

    func getAllMessages() async -> [SynthMessage] {
        let indexedMesages = localMessages + (await async.messages)
        let sortedMessages = indexedMesages.lazy.sorted { $0.id < $1.id }.map { $0.message }
        if let firstErrorIndex = sortedMessages.firstIndex(where: { $0.type == .error }) {
            return Array(sortedMessages.prefix(through: firstErrorIndex))
        } else {
            return sortedMessages
        }
    }

    actor AsyncMessageManager {
        nonisolated private let errorFlag: Atomic<Bool> = .init(false)

        fileprivate var messages: [(id: UInt32, message: SynthMessage)] = []

        nonisolated var hasError: Bool {
            errorFlag.load(ordering: .relaxed)
        }

        func add(
            at debugLoc: consuming DebugLocation,
            in frames: [DebugFrame],
            id: UInt32,
            type: SynthMessage.Kind,
            _ message: String
        ) {
            if type == .error {
                errorFlag.store(true, ordering: .relaxed)
            }
            let message = SynthMessage(at: debugLoc, in: frames, type: type, message: message)
            messages.append((id, message))
        }
    }
}
