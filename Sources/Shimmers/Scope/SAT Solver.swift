//
//  Shimmers/Scope/SAT Solver.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Foundation

enum SolverResult: Equatable {
    case satisfiable
    case unsatifiable
    case timeout
}

func locate(tool: String) -> URL? {
    let fileManager = FileManager.default

    let process = Process()
    process.executableURL = URL(fileURLWithPath: ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/bash")
    process.arguments = ["-l", "-c", "which \(tool)"]
    process.environment = ProcessInfo.processInfo.environment

    let outputPipe = Pipe()
    process.standardOutput = outputPipe

    do {
        try process.run()
    } catch {
        print(error.localizedDescription)
        return nil
    }
    process.waitUntilExit()

    let data = outputPipe.fileHandleForReading.availableData
    guard let string = String(data: data, encoding: .utf8) else { return nil }

    let path = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !path.isEmpty else { return nil }

    let url = URL(fileURLWithPath: path, isDirectory: false)
    guard fileManager.isReadableFile(atPath: path) else { return nil }
    return url
}

internal func proveKissat(problem: String, solverURL: URL, timeout: Int, priority: QualityOfService, needModel: Bool) -> (result: SolverResult, model: [UInt64: Bool]?, duration: TimeInterval) {

    let solver = Process()
    var args = ["-q", "--time=\(timeout)", "--sat"]
    if !needModel { args.append("-n") }
    solver.arguments = args
    solver.executableURL = solverURL

    let inputPipe = Pipe()
    let outputPipe: Pipe? = needModel ? Pipe() : nil
    solver.standardInput = inputPipe
    solver.standardOutput = outputPipe
    solver.standardError = nil
    solver.qualityOfService = priority

    let beginTime = Date()
    let output: Data?

    do {
        try solver.run()
        try inputPipe.fileHandleForWriting.write(contentsOf: problem.data(using: .ascii)!)
        try inputPipe.fileHandleForWriting.close()
        solver.waitUntilExit()
        output = try? outputPipe?.fileHandleForReading.readToEnd()
    } catch {
        fatalError(error.localizedDescription)
    }

    let duration = Date().timeIntervalSince(beginTime)

    let status = solver.terminationStatus

    switch solver.terminationStatus {
    case 20:
        return (.unsatifiable, nil, duration)
    case 10:
        let model: [UInt64: Bool]?
        if let output = output {
            let outputString = String(data: output, encoding: .ascii)!
            model = extractModel(from: outputString)
        } else {
            model = nil
        }
        return (.satisfiable, model, duration)
    default:
        if status == 0, duration >= Double(timeout) - 0.1 {
            return (result: .timeout, nil, duration)
        }
        fatalError("Sat solver encountered with error code \(status)")
    }
}

private func extractModel(from string: String) -> [UInt64: Bool] {
    var result: [UInt64: Bool] = [:]
    for line in string.lazy.split(omittingEmptySubsequences: true, whereSeparator: \.isWhitespace) {
        guard let integer = Int(String(line)) else { continue }
        result[UInt64(integer.magnitude)] = integer > 0
    }
    result.removeValue(forKey: 0)
    result.removeValue(forKey: 1)
    return result
}
