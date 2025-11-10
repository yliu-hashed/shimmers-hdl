//
//  Shimmers/Scope/Scope - Condition.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

extension _SynthScope {
    internal class CondFrame {
        var parent: CondFrame? = nil
        var commulativeCondWires: Set<_WireID>
        var condWires: Set<_WireID>

        var owningVirtuals: Set<UInt32> = []
        var initial: [UInt32: [_WireID]] = [:]
        var changes: [UInt32: [_WireID]] = [:]

        init(parent: CondFrame? = nil, condWires: Set<_WireID> = []) {
            self.parent = parent
            if let old = parent?.commulativeCondWires {
                commulativeCondWires = condWires.union(old)
                self.condWires = condWires.subtracting(old)
            } else {
                commulativeCondWires = []
                self.condWires = condWires
            }
        }

        func tryObtainVirtual(id: UInt32) -> [_WireID]? {
            if let wires = changes[id] {
                return wires
            }
            if owningVirtuals.contains(id) {
                return initial[id]
            }
            if let parent = parent {
                return parent.obtainVirtual(id: id)
            }
            return nil
        }

        func obtainVirtual(id: UInt32) -> [_WireID]? {
            if let wires = changes[id] {
                return wires
            }
            if owningVirtuals.contains(id) {
                return initial[id]
            }
            if let parent = parent {
                return parent.obtainVirtual(id: id)
            }
            fatalError("Virtual wire \(id) does not exist")
        }

        func detachVirtual(id: UInt32) -> [_WireID]? {
            guard owningVirtuals.contains(id) else {
                fatalError("Virtual wire \(id) is not owned by the current scope")
            }
            owningVirtuals.remove(id)
            return initial.removeValue(forKey: id)
        }

        func update(id: UInt32, value: [_WireID]) {
            if owningVirtuals.contains(id) {
                initial[id] = value
            } else {
                changes[id] = value
            }
        }
    }

    fileprivate enum FrameEntryMode: Sendable {
        case always
        case never
        case normal
    }

    fileprivate func enterFrame(_ conditions: consuming [BoolRef], alwaysSynth: Bool = false) -> FrameEntryMode {
        guard !didEncounteredErrors() else { return .never }
        // solve for the set of new conditions
        let condWires = Set(conditions.map(\.wireID))
        guard alwaysSynth || !condWires.contains(false) else {
            return .never
        }
        guard condWires != [ true ] else {
            return .always
        }

        currFrame = CondFrame(parent: currFrame, condWires: condWires)
        return .normal
    }

    fileprivate func exitFrame() {
        let frame = currFrame
        let parent = frame.parent!

        let wire = self.addAND(reduce: frame.condWires)
        for (id, change) in frame.changes {
            if let old = parent.obtainVirtual(id: id) {
                let new = buildMux(cond: wire, lhs: change, rhs: old)
                parent.update(id: id, value: new)
            } else {
                parent.update(id: id, value: change)
            }
        }
        currFrame = parent
    }

    internal func currentConditions() -> Set<_WireID> {
        return currFrame.commulativeCondWires
    }

    @usableFromInline
    internal func createVirtualID<Ref: WireRef>(for type: Ref.Type, initialValue: Ref?) -> UInt32 {
        let id = genVirtualID()
        currFrame.owningVirtuals.insert(id)
        if let value = initialValue {
            currFrame.initial[id] = value._getAllWireIDs()
        }
        return id
    }

    @usableFromInline
    internal func detachVirtual<Ref: WireRef>(_ id: UInt32) -> Ref {
        let wires = currFrame.detachVirtual(id: id)!
        return Ref(from: wires)
    }

    @usableFromInline
    internal func getVirtual<Ref: WireRef>(id: UInt32) -> Ref {
        guard !didEncounteredErrors() else {
            var popper = _ZeroWirePopper()
            return Ref(_byPoppingBits: &popper)
        }
        guard let wires = currFrame.obtainVirtual(id: id) else { fatalError() }
        return Ref(from: wires)
    }

    @usableFromInline
    internal func tryGetVirtualWires(id: UInt32) -> [_WireID]? {
        guard !didEncounteredErrors() else { return nil }
        return currFrame.tryObtainVirtual(id: id)
    }

    @usableFromInline
    internal func virtualChanged<Ref: WireRef>(id: UInt32, to ref: Ref) {
        guard !didEncounteredErrors() else { return }
        currFrame.update(id: id, value: ref._getAllWireIDs())
    }
}

public func _if(_ conditions: BoolRef..., alwaysSynth: Bool = false, block: () -> Void) {
    let entryResult = _unsafeScopeIsolated { scope in
        scope.enterFrame(conditions, alwaysSynth: alwaysSynth)
    }
    switch entryResult {
    case .always:
        block()
    case .never:
        return
    case .normal:
        block()
        _unsafeScopeIsolated { scope in
            scope.exitFrame()
        }
    }
}
