//
//  Shimmers/Scope/Debugging.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

public func _pushDebugFrame(file: StaticString, line: UInt, function: StaticString) -> _FrameRecorder {
    return _unsafeScopeIsolated { scope in
        let debugLoc = DebugLocation(file: file, line: line)
        return scope.debugRecorder.pushDebugFrame(debugLoc, of: function)
    }
}

public func _popDebugFrame() {
    _unsafeScopeIsolated { scope in
        scope.debugRecorder.popDebugFrame()
    }
}

public class _FrameRecorder: @unchecked Sendable {
    internal var lastDebugLoc: DebugLocation
    internal var function: StaticString
    internal var symbols: [String: SymbolValue] = [:]

    enum SymbolValue {
        case virtual(id: UInt32)
        case concrete(value: [_WireID])
    }

    init(lastDebugLoc: DebugLocation, function: StaticString) {
        self.function = function
        self.lastDebugLoc = lastDebugLoc
    }

    var debugFrame: DebugFrame {
        return DebugFrame(lastDebugLoc: lastDebugLoc, function: function)
    }

    func materializeSymbols(in scope: isolated _SynthScope) -> [String: [CNFBuidler.SATVar]] {
        var symbolTable: [String: [CNFBuidler.SATVar]] = [:]
        for (name, value) in symbols {
            switch value {
            case .concrete(value: let v):
                symbolTable[name] = v.map({ scope.cnfBuilder.getSATVar(of: $0) })
            case .virtual(let id):
                if let wires = scope.tryGetVirtualWires(id: id) {
                    symbolTable[name] = wires.map({ scope.cnfBuilder.getSATVar(of: $0) })
                }
            }
        }
        return symbolTable
    }

    public func record<T>(name: String, value: T) {
        if let wire = value as? any WireRef {
            let wires = wire._getAllWireIDs()
            symbols[name] = .concrete(value: wires)
        }
    }

    public func updateLocation(file: StaticString, line: UInt) {
        lastDebugLoc = DebugLocation(file: file, line: line)
    }
}

class DebugRecorder {
    var frames: [_FrameRecorder] = []

    var lastDebugLoc: DebugLocation? {
        return frames.last?.lastDebugLoc
    }

    func simpleFrames() -> [DebugFrame] {
        return frames.map { $0.debugFrame }
    }

    func materializeFrames(in scope: isolated _SynthScope) -> [(frame: DebugFrame, symbols: [String: [CNFBuidler.SATVar]])] {
        return frames.map {
            (frame: $0.debugFrame,
             symbols: $0.materializeSymbols(in: scope))
        }
    }

    @inlinable
    func pushDebugFrame(_ debugLoc: consuming DebugLocation, of function: StaticString) -> _FrameRecorder {
        let newFrame = _FrameRecorder(lastDebugLoc: debugLoc, function: function)
        frames.append(newFrame)
        return newFrame
    }

    @inlinable
    func popDebugFrame() {
        frames.removeLast()
    }
}
