//
//  Shimmers/Scope/Scope - Prove Assume.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension _SynthScope {

    static let proveAssumeRuntimeLimit: Int = 30

    @usableFromInline
    func solverAssume(
        _ condition: BoolRef,
        type: AssertionType,
        msg: String? = nil,
        debugLoc: DebugLocation? = nil
    ) {
        guard !didEncounteredErrors() else { return }

        let wireID = condition.wireID
        if wireID == true { return }

        let debugLoc = debugLoc ?? debugRecorder.lastDebugLoc ?? .unknown
        let debugFrames = debugRecorder.simpleFrames()

        guard let kissatPath = kissatPath else {
            messageManager.add(
                at: debugLoc, in: debugFrames, type: .warning,
                "Solving skipped. Kissat binary not found."
            )
            return
        }

        cnfBuilder.assert(condition.wireID)

        let msg = type.message(of: .assume, for: msg)

        guard enabledAssertions.contains(.assumption) else { return }

        let problem = cnfBuilder.emitProblemCNF()

        let asyncMessageManager = messageManager.async
        let asyncMessageID = messageManager.reserveMessageID()

        let task = Task.detached { [kissatPath] in
            let (result, _) = await proveKissat(
                problem: problem,
                path: kissatPath,
                timeout: Self.proveAssumeRuntimeLimit
            )

            switch result {
            case .satisfiable:
                return
            case .unsatifiable:
                await asyncMessageManager.add(
                    at: debugLoc, in: debugFrames, id: asyncMessageID, type: .error,
                    "Assertion is contradictory: \(msg)"
                )
            case .timeout:
                await asyncMessageManager.add(
                    at: debugLoc, in: debugFrames, id: asyncMessageID, type: .warning,
                    "Cannot prove whether assumption is contradictory in reasonable time."
                )
            }
        }
        pendingTasks.append(task)
    }
}

@inlinable
public func _proveAssume(
    _ condition: BoolRef,
    type: AssertionType,
    msg: String? = nil,
    debugLoc: DebugLocation? = nil
) {
    _unsafeScopeIsolated { scope in
        scope.solverAssume(
            condition,
            type: type,
            msg: msg,
            debugLoc: debugLoc
        )
    }
}
