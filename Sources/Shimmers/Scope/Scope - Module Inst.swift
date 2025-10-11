//
//  Shimmers/Scope/Scope - Module Inst.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public struct _DetachedPortValueInfo: Sendable {
    internal var value: any WireRef
    internal var shape: _DetachedPortShape

    public init(value: any WireRef, name: String, isMutable: Bool) {
        self.value = value
        self.shape = _DetachedPortShape(
            name: name,
            type: type(of: value),
            isMutable: isMutable
        )
    }

    public init(value: any WireRef, shape: _DetachedPortShape) {
        self.value = value
        self.shape = shape
    }
}

@inlinable
public func _insertDetached(
    name: String,
    portInfos: consuming [_DetachedPortValueInfo],
    returning returnType: (any WireRef.Type)?
) -> ((any WireRef)?, [any WireRef]) {
    return _unsafeScopeIsolated { scope in
        scope.insertDetached(
            name: name,
            portInfos: portInfos,
            returning: returnType,
        )
    }
}

extension _SynthScope {
    @usableFromInline
    func insertDetached(
        name: String,
        portInfos: [_DetachedPortValueInfo],
        returning returnType: (any WireRef.Type)?,
    ) -> ((any WireRef)?, [any WireRef]) {

        // figure out naming convention
        let naming = NamingRequirement(infos: portInfos)

        let module = builder.addSubmodule(name: moduleNamePrefix + name)

        for info in portInfos {
            info.value._applyPerPart(parentName: naming.inArgPrefix + info.shape.name) { name, part in
                module.addInput(name: name, wires: part)
            }
        }

        var mutatedArgs: [any WireRef] = []
        for info in portInfos {
            guard info.shape.isMutable else { continue }
            let value = info.shape.type.init(parentName: naming.outArgPrefix + info.shape.name) { name, bitWidth in
                module.addOutput(name: name, width: bitWidth)
            }
            mutatedArgs.append(value)
        }

        let retValue: (any WireRef)?
        if let returnType = returnType {
            retValue = returnType.init(parentName: naming.outRetName) { name, bitWidth in
                module.addOutput(name: name, width: bitWidth)
            }
        } else {
            retValue = nil
        }

        module.finish()

        return (retValue, mutatedArgs)
    }
}
