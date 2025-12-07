//
//  Shimmers/Scope/Scope - Prove Loop.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Foundation

internal struct SolverHistoryEntry {
    var hintMin: Int
    var hintMax: Int?
    var runs: Int = 0
    var cumulativeRuntime: Double = 0
    var tooLongWarningPrinted: Bool = false
}

extension _SynthScope {

    static let proveLoopRuntimeLimit: Int = 10
    static let proveLoopRuntimeLimitTotal: Double = 100

    @usableFromInline
    func discardLoopHistory(for loopID: UInt64?) {
        guard let loopID else { return }
        solverHistory[loopID] = nil
    }

    @usableFromInline
    func proveLoop(
        _ condition: BoolRef, id loopID: inout UInt64?,
        hintMin: Int = 0,
        hintMax: Int? = nil,
        debugLoc: DebugLocation?
    ) -> Bool {
        guard !didEncounteredErrors() else { return false }

        let wireID = condition.wireID

        // create ID and fetch history
        let id: UInt64
        var history: SolverHistoryEntry
        if let loopID {
            id = loopID
            history = solverHistory[id]!
        } else {
            id = genLoopID()
            loopID = id
            history = SolverHistoryEntry(hintMin: hintMin, hintMax: hintMax)
        }
        history.runs += 1
        defer { solverHistory[id] = history }

        // always unroll if hinted
        if history.runs <= history.hintMin {
            return true
        }
        // stop unroll if hinted
        if let hintMax = history.hintMax, history.runs > hintMax {
            return false
        }
        // constant
        if let constant = wireID.constant {
            return constant
        }

        let debugLoc = debugLoc ?? debugRecorder.lastDebugLoc ?? .unknown

        guard let kissatURL = kissatURL else {
            let debugFrames = debugRecorder.simpleFrames()
            messageManager.add(
                at: debugLoc, in: debugFrames, type: .error,
                "Unable to unroll loops. Kissat binary not found."
            )
            return false
        }

        // emit and solve the sat problem
        let problem = cnfBuilder.emitProblemCNF(newClauseList: [[wireID]])
        let (result, _, duration) = proveKissat(
            problem: problem,
            solverURL: kissatURL,
            timeout: Self.proveLoopRuntimeLimit,
            priority: .default,
            needModel: false
        )

        // update stats
        history.cumulativeRuntime += max(Double(duration) - 0.1, 0)

        // warn if already took too long
        if !history.tooLongWarningPrinted, history.cumulativeRuntime > Self.proveLoopRuntimeLimitTotal {
            messageManager.add(
                at: debugLoc,
                in: debugRecorder.simpleFrames(),
                type: .error,
                "Has spent a total of more than \(Self.proveLoopRuntimeLimit)s (\(history.runs) iterations) on this loop. Consider converting it to bounded 'for' loops, or add hint instead."
            )
            history.tooLongWarningPrinted = true
        }

        // return result
        switch result {
        case .satisfiable:
            return true
        case .unsatifiable:
            cnfBuilder.assert(!wireID)
            return false
        case .timeout:
            messageManager.add(
                at: debugLoc,
                in: debugRecorder.simpleFrames(),
                type: .warning,
                "Cannot prove unroll condition in reasonable time, use bounded 'for' loops instead"
            )
            return false
        }
    }
}

@inlinable
public func _proveLoop(
    _ condition: BoolRef,
    id loopID: inout UInt64?,
    hintMin: Int = 0,
    hintMax: Int? = nil,
    debugLoc: DebugLocation? = nil
) -> Bool {
    return _unsafeScopeIsolated { scope in
        return scope.proveLoop(
            condition,
            id: &loopID,
            hintMin: hintMin,
            hintMax: hintMax,
            debugLoc: debugLoc
        )
    }
}

@inlinable
public func _discardLoopHistory(for loopID: UInt64?) {
    guard let loopID = loopID else { return }
    _unsafeScopeIsolated { scope in
        scope.discardLoopHistory(for: loopID)
    }
}
