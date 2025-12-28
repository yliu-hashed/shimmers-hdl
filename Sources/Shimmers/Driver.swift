//
//  Shimmers/Driver.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Foundation

public struct _ScopeControl {
    @TaskLocal
    public static var currentScope: _SynthScope? = nil
}

public struct _WaitableSynthJob: Sendable {
    let task: Task<(),Never>
    let fileName: String?

    init(task: Task<(), Never>, fileName: String? = nil) {
        self.task = task
        self.fileName = fileName
    }

    func wait() async {
        await task.value
    }
}

public struct SynthOptions: Sendable {
    public var kissat: SolverLocation
    public var disabledAssertions: AssertionSet
    public var printIncludes: Bool = false
    public var fileNamePrefix: String = ""
    public var moduleNamePrefix: String = ""

    public init(
        kissat: SolverLocation = .inferFromPath,
        disabledAssertions: AssertionSet = [],
        printIncludes: Bool = false,
        fileNamePrefix: String = "",
        moduleNamePrefix: String = ""
    ) {
        self.kissat = kissat

        self.disabledAssertions = disabledAssertions
        self.printIncludes = printIncludes
        self.fileNamePrefix = fileNamePrefix
        self.moduleNamePrefix = moduleNamePrefix
    }

    static var testing: SynthOptions {
        return Self(
            kissat: .none,
            disabledAssertions: [
                .bound,
                .overflowConvert,
                .overflowMath,
                .assumption
            ]
        )
    }
}

public actor SynthDriver {
    @TaskLocal internal static var currentDriver: SynthDriver? = nil

    public private(set) var directory: URL
    public private(set) var entries: Set<String> = []
    public private(set) var working: Set<String> = []
    private var nameTable: [String: String] = [:]

    public private(set) var options: SynthOptions

    private var waiting: [UnsafeContinuation<Void, Never>] = []

    private var notifiers: [@Sendable (Notification) -> Void] = []
    private var messages: [SynthMessage] = []

    public init(directory: URL, with options: SynthOptions) {
        self.directory = directory
        self.options = options
    }

    public enum Notification: Sendable {
        case begin(name: String)
        case done(name: String, messages: [SynthMessage])
    }

    func updateNotifiers(of notification: Notification) {
        for notifier in notifiers {
            notifier(notification)
        }
    }

    public func addNotifier(_ notifier: @escaping @Sendable (Notification) -> Void) {
        notifiers.append(notifier)
    }

    private func begin(name: String, uniqueName: String) -> Bool {
        if let existingUniqueName = nameTable[name] {
            guard existingUniqueName == uniqueName else {
                fatalError("The name of '\(name)' is already used by '\(existingUniqueName)'")
            }
        }
        nameTable[name] = uniqueName
        if entries.contains(name) { return false }
        entries.insert(name)
        working.insert(name)
        updateNotifiers(of: .begin(name: name))
        return true
    }

    private func finished(name: String, verilog: String, messages: [SynthMessage]) {
        assert(working.contains(name))
        // store file
        let fileName: String = options.fileNamePrefix + buildFileName(for: name) + ".v"
        let fileURL = directory.appending(component: fileName)
        let data = verilog.data(using: .utf8)!
        try! data.write(to: fileURL)

        // resume all waitings
        working.remove(name)
        self.messages.append(contentsOf: messages)
        updateNotifiers(of: .done(name: name, messages: messages))
        if working.isEmpty {
            for cont in waiting {
                cont.resume()
            }
            waiting = []
        }
    }

    /// Begin a new scope and run the following blocks
    internal func generate(for name: String, uniqueName: String, block: @Sendable @escaping (isolated _SynthScope) -> Void) {
        guard begin(name: name, uniqueName: uniqueName) else { return }
        Task {
            let scope = _SynthScope(name: name, with: options)
            await _ScopeControl.$currentScope.withValue(scope) {
                await block(scope)
            }
            let messages = await scope.awaitAllPendingTasks()
            let verilog = await scope.emitVerilog(withIncludes: options.printIncludes)
            finished(name: name, verilog: verilog, messages: messages)
        }
    }

    func requestToWait(continuation: UnsafeContinuation<Void, Never>) {
        guard !working.isEmpty else {
            continuation.resume()
            return
        }
        waiting.append(continuation)
    }

    public func waitForAll() async {
        await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>)->Void in
            requestToWait(continuation: continuation)
        }
    }
}

public extension SynthDriver {

    /// Generating a top level module without waiting.
    ///
    /// Use ``topLevel(name:of:)`` to refer to a top level generator created by the ``Detached()`` macro.
    nonisolated func enqueue(_ type: TopLevelGenerator.Type) async {
        let work = SynthDriver.$currentDriver.withValue(self) {
            type._generate()
        }
        await work.wait()
    }
}
