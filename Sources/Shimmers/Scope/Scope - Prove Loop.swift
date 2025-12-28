//
//  Shimmers/Scope/Scope - Prove Loop.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Foundation

public struct _LoopInfo: Sendable {
    let hintMin: Int
    let hintMax: Int?
    let debugLoc: DebugLocation?
    var runs: Int = 0
    var cumulativeRuntime: Double = 0
    var tooLongWarningPrinted: Bool = false

    public init(hintMin: Int = 0, hintMax: Int? = nil, debugLoc: DebugLocation?) {
        self.hintMax = hintMax
        self.hintMin = hintMin
        self.debugLoc = debugLoc
    }
}

extension _SynthScope {

    static let proveLoopRuntimeLimit: Int = 10
    static let proveLoopRuntimeLimitTotal: Double = 100

    @usableFromInline
    func proveLoop(
        _ condition: BoolRef,
        for loopInfo: inout _LoopInfo
    ) -> Bool {
        guard !didEncounteredErrors() else { return false }

        let wireID = condition.wireID

        // create ID and fetch history
        loopInfo.runs += 1

        // always unroll if hinted
        if loopInfo.runs <= loopInfo.hintMin {
            return true
        }
        // stop unroll if hinted
        if let hintMax = loopInfo.hintMax, loopInfo.runs > hintMax {
            return false
        }
        // constant
        if let constant = wireID.constant {
            return constant
        }

        let debugLoc = loopInfo.debugLoc ?? debugRecorder.lastDebugLoc ?? .unknown

        // TODO: Fix Prove Loop

        let debugFrames = debugRecorder.simpleFrames()
        messageManager.add(
            at: debugLoc, in: debugFrames, type: .error,
            "Unable to unroll loops. Not yet supported."
        )
        return false
    }
}

@inlinable
public func _proveLoop(
    _ condition: BoolRef,
    for loopInfo: inout _LoopInfo
) -> Bool {
    return _unsafeScopeIsolated { scope in
        return scope.proveLoop(
            condition,
            for: &loopInfo
        )
    }
}
