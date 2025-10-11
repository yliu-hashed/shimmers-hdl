//
//  Shimmers/Scope/Module Gen.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public struct _DetachedPortShape: Sendable {
    internal var name: String
    internal var type: any WireRef.Type
    internal var isMutable: Bool

    public init(name: String, type: any WireRef.Type, isMutable: Bool) {
        self.name = name
        self.type = type
        self.isMutable = isMutable
    }
}

public func _createDetached(
    for name: String,
    uniqueName: String,
    portInfos: [_DetachedPortShape],
    returning returnType: (any WireRef.Type)?,
    generating block: @escaping @Sendable ([any WireRef]) -> ((any WireRef)?, [any WireRef])
) -> _WaitableSynthJob {
    // figure out naming convention
    let naming = NamingRequirement(infos: portInfos)

    guard let driver = SynthDriver.currentDriver else {
        fatalError("You are calling \(#function) function outside of the scope of a driver!")
    }

    let task = Task {
        await driver.generate(for: name, uniqueName: uniqueName + " synth") { scope in
            // create all inputs
            var values: [any WireRef] = []
            values.reserveCapacity(portInfos.count)
            for info in portInfos {
                let value = info.type.init(
                    byPortMapping: scope,
                    parentName: naming.inArgPrefix + info.name
                )
                values.append(value)
            }
            // call work function
            let (result, mutated) = block(values)
            // set mutated ports
            for (index, info) in portInfos.lazy.filter(\.isMutable).enumerated() {
                mutated[index]._addResult(parentName: naming.outArgPrefix + info.name, to: scope)
            }
            // returned value
            if let result = result {
                result._addResult(parentName: naming.outRetName, to: scope)
            }
        }
    }

    let fileName = buildFileName(for: name)
    return _WaitableSynthJob(task: task, fileName: fileName + ".v")
}

extension _SynthScope {
    func addWaiting(_ wait: _WaitableSynthJob) {
        pendingTasks.append(wait.task)
    }
}

public func _addWaiting(_ wait: _WaitableSynthJob) {
    _unsafeScopeIsolated { scope in
        scope.addWaiting(wait)
    }
}
