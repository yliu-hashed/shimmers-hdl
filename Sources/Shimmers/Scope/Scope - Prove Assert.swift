//
//  Shimmers/Scope/Scope - Prove Assert.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension _SynthScope {

    static let proveAssertRuntimeLimit: Int = 30

    @usableFromInline
    func proveAssert(
        _ condition: BoolRef,
        type: AssertionType,
        msg: String? = nil,
        debugLoc: DebugLocation? = nil
    ) {
        guard !didEncounteredErrors() else { return }

        let wireID = condition.wireID
        if wireID == true { return }

        let debugFrames = debugRecorder.simpleFrames()
        let debugLoc = debugLoc ?? debugRecorder.lastDebugLoc ?? .unknown

        guard let kissatURL = kissatURL else {
            messageManager.add(
                at: debugLoc, in: debugFrames, type: .warning,
                "Solving skipped. Kissat binary not found."
            )
            return
        }

        let msg = type.message(of: .assert, for: msg)

        guard enabledAssertions.contains(type) else { return }

        // find precondition
        var newClauseList: [[_WireID]] = [[!condition.wireID]]
        for wireID in currentConditions() {
            switch wireID {
            case false:
                return
            case true:
                continue
            default:
                break
            }
            newClauseList.append([wireID])
        }

        // look for assignments where preconditions are all true AND the assertion is false

        // solve the sat problem
        let problem = cnfBuilder.emitProblemCNF(newClauseList: newClauseList)

        let asyncMessageManager = messageManager.async
        let asyncMessageID = messageManager.reserveMessageID()

        let task = Task.detached {
            let (result, _, duration) = proveKissat(
                problem: problem,
                solverURL: kissatURL,
                timeout: Self.proveAssertRuntimeLimit,
                priority: .background,
                needModel: false
            )

            if duration > 10 {
                await asyncMessageManager.add(
                    at: debugLoc,
                    in: debugFrames,
                    id: asyncMessageID,
                    type: .warning,
                    "Assertion is taking too long."
                )
            }

            switch result {
            case .satisfiable:
                await asyncMessageManager.add(
                    at: debugLoc,
                    in: debugFrames,
                    id: asyncMessageID,
                    type: .error, msg
                )
            case .unsatifiable:
                return
            case .timeout:
                await asyncMessageManager.add(
                    at: debugLoc,
                    in: debugFrames,
                    id: asyncMessageID,
                    type: .warning,
                    "Cannot disprove assertion in reasonable time."
                )
            }
        }
        pendingTasks.append(task)
    }

}

@inlinable
public func _proveAssert(
    _ condition: BoolRef,
    type: AssertionType,
    msg: String? = nil,
    debugLoc: DebugLocation? = nil
) {
    _unsafeScopeIsolated { scope in
        scope.proveAssert(
            condition,
            type: type,
            msg: msg,
            debugLoc: debugLoc
        )
    }
}

@inlinable
public func _proveNever(
    type: AssertionType,
    msg: String? = nil,
    debugLoc: DebugLocation? = nil
) {
    _unsafeScopeIsolated { scope in
        scope.proveAssert(
            false,
            type: type,
            msg: msg,
            debugLoc: debugLoc
        )
    }
}
