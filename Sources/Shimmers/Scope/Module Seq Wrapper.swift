//
//  Shimmers/Scope/Module Seq Wrapper.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public func _createSequentialWrapper(
    for name: String,
    uniqueName: String,
    portInfos: [_DetachedPortShape],
    returning returnType: (any WireRef.Type)?,
    type: any WireRef.Type,
    generating block: @escaping @Sendable () -> ()
) -> _WaitableSynthJob {
    let naming = NamingRequirement(infos: portInfos, hasOtherMutability: true)

    guard let driver = SynthDriver.currentDriver else {
        fatalError("You are calling \(#function) function outside of the scope of a driver!")
    }

    let task = Task {
        await driver.generate(for: name, uniqueName: uniqueName + " sequential") { scope in
            block()

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
            // create self DFFs
            let selfRef = scope.reserveDFF(for: type)

            // create a list of port infos
            var infos: [_DetachedPortValueInfo] = []
            infos.reserveCapacity(portInfos.count + 1)
            // add self and other ports
            infos.append(.init(value: selfRef, name: "self", isMutable: true))
            for i in 0..<portInfos.count {
                let shape = portInfos[i]
                let value = values[i]
                infos.append(.init(value: value, shape: shape))
            }

            // add the detached module
            let (result, mutated) = _insertDetached(name: name + "_helper", portInfos: infos, returning: returnType)

            // bind the DFF back
            scope.bindDFF(selfRef, to: mutated[0])

            // set mutated ports
            for (index, info) in portInfos.lazy.filter(\.isMutable).enumerated() {
                mutated[index + 1]._addResult(parentName: naming.outArgPrefix + info.name, to: scope)
            }
            // returned value
            if let result = result {
                result._addResult(parentName: naming.outRetName, to: scope)
            }
        }
    }

    let fileName = buildFileName(for: name)
    return _WaitableSynthJob(task: task, fileName: fileName)
}
