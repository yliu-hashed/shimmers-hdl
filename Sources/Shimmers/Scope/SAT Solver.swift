//
//  Shimmers/Scope/SAT Solver.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Foundation
import Subprocess
#if canImport(System)
@preconcurrency import System
#else
@preconcurrency import SystemPackage
#endif

public enum SolverLocation: Sendable, Equatable {
    case none
    case inferFromPath
    case custom(path: String)

    func resolve(name: String) -> FilePath? {
        switch self {
        case .none:
            return nil
        case .inferFromPath:
            let exec = Executable.name(name)
            return try? exec.resolveExecutablePath(in: .inherit)
        case .custom(let pathString):
            return FilePath(pathString)
        }
    }
}

enum SolverResult: Equatable {
    case satisfiable
    case unsatifiable
    case timeout
}

internal func proveKissat(
    problem: consuming String,
    path: FilePath,
    timeout: Int
) async -> (
    result: SolverResult,
    duration: TimeInterval
) {
    let exec = Executable.path(path)

    let startTime = Date()

    let status: TerminationStatus
    do {
        let result = try await Subprocess.run(
            exec,
            arguments: ["-q", "--time=\(timeout)", "--sat"],
            input: .string(problem),
            output: .discarded,
            error: .discarded
        )
        status = result.terminationStatus
    } catch {
        fatalError("Cannot ran solver: \(error.localizedDescription)")
    }

    let duration = Date().timeIntervalSince(startTime)

    switch status {
    case .exited(20):
        return (.unsatifiable, duration)
    case .exited(10):
        return (.satisfiable, duration)
    default:
        if status == .exited(0), duration >= Double(timeout) - 0.1 {
            return (result: .timeout, duration)
        }
        fatalError("Sat solver encountered with error code \(status)")
    }
}

internal func proveKissatModel(
    problem: consuming String,
    path: FilePath,
    timeout: Int
) async -> (
    result: SolverResult,
    model: [UInt64: Bool]?,
    duration: TimeInterval
) {
    let exec = Executable.path(path)

    let startTime = Date()

    let status: TerminationStatus
    let model: [UInt64: Bool]?
    do {
        let result = try await Subprocess.run(
            exec,
            arguments: ["-q", "--time=\(timeout)", "--sat"],
            input: .string(problem),
            error: .discarded
        ) { execution, output in
            var parsor = ModelParsor()
            for try await chunk in output {
                chunk.withUnsafeBytes { ptr in
                    for byte in ptr {
                        parsor.process(byte: byte)
                    }
                }
            }
            parsor.finalize()
            return parsor.model
        }

        status = result.terminationStatus
        if status == .exited(10) {
            model = result.value
        } else {
            model = nil
        }
    } catch {
        fatalError("Cannot ran solver: \(error.localizedDescription)")
    }

    let duration = Date().timeIntervalSince(startTime)

    switch status {
    case .exited(20):
        return (.unsatifiable, nil, duration)
    case .exited(10):
        return (.satisfiable, model, duration)
    default:
        if status == .exited(0), duration >= Double(timeout) - 0.1 {
            return (result: .timeout, nil, duration)
        }
        fatalError("Sat solver encountered with error code \(status)")
    }
}

private struct ModelParsor {
    var model: [UInt64: Bool] = [:]
    private var polarity: Bool = true
    private var value: UInt64 = 0

    mutating func process(byte: UInt8) {
        let scalar = UnicodeScalar(byte)
        switch scalar {
        case "-":
            polarity = false
        case "0"..<"9":
            let digit = UInt64(scalar.value) - 48
            value = value * 10 + digit
        default:
            value = 0
            polarity = true
            if value > 1 {
                model[value] = polarity
            }
            return
        }
    }

    mutating func finalize() {
        if value > 1 {
            model[value] = polarity
        }
    }
}
