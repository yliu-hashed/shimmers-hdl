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

public class _FrameRecorder: @unchecked Sendable {
    internal var recorder: DebugRecorder
    internal var lastDebugLoc: DebugLocation
    internal var function: StaticString

    init(recorder: DebugRecorder, lastDebugLoc: DebugLocation, function: StaticString) {
        self.recorder = recorder
        self.function = function
        self.lastDebugLoc = lastDebugLoc
    }

    var debugFrame: DebugFrame {
        return DebugFrame(lastDebugLoc: lastDebugLoc, function: function)
    }

    public func updateLocation(file: StaticString, line: UInt) {
        lastDebugLoc = DebugLocation(file: file, line: line)
    }

    public func pop() {
        recorder.popDebugFrame()
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

    @inlinable
    func pushDebugFrame(_ debugLoc: consuming DebugLocation, of function: StaticString) -> _FrameRecorder {
        let newFrame = _FrameRecorder(
            recorder: self,
            lastDebugLoc: debugLoc,
            function: function
        )
        frames.append(newFrame)
        return newFrame
    }

    @inlinable
    func popDebugFrame() {
        frames.removeLast()
    }
}
