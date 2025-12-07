//
//  ShimmersCLIWrapper/Printing.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Foundation
import Shimmers

func eraseLine() {
    print("\u{001B}[1A\u{001B}[2K", terminator: "")
}

enum Color: Int {
    case green = 32
    case yellow = 33
    case red = 31
    case cyan = 36
}

func setColor(_ color: Color) {
    print("\u{001B}[0;\(color.rawValue)m", terminator: "")
}

func setDefaultColor() {
    print("\u{001B}[0;0m", terminator: "")
}

@MainActor
protocol ProgressPrinter: Sendable {
    func update(of notification: SynthDriver.Notification)
    var errorCount: Int { get }
}

func makePrinter() -> any ProgressPrinter {
    guard let term = ProcessInfo.processInfo.environment["TERM"], term != "dumb" else {
        return BasicPrinter()
    }
    return FancyPrinter()
}

@MainActor
final class BasicPrinter: ProgressPrinter {
    var moduleCount: Int = 0
    var finishedCount: Int = 0
    var errorCount: Int = 0

    func update(of notification: SynthDriver.Notification) {
        switch notification {
        case .begin(let name):
            moduleCount += 1
            print("[\(finishedCount)/\(moduleCount)]: STARTING \(name)")
        case .done(let name, let messages):
            finishedCount += 1
            print("[\(finishedCount)/\(moduleCount)]: FINISHED \(name)")
            for message in messages {
                if message.type == .error { errorCount += 1 }
                print("  \(message)")
                printMessageStack(of: message)
            }
        }
    }
}

@MainActor
final class FancyPrinter: ProgressPrinter {
    var finishedCount: Int = 0
    var workingModuleList: [String] = []
    var errorCount: Int = 0

    func update(of notification: SynthDriver.Notification) {
        switch notification {
        case .begin(let name):
            // simply append the new working module down below
            printWorkingModule(name: name)
            workingModuleList.append(name)
        case .done(let name, let messages):
            // retract each printed working modules
            for _ in 0..<workingModuleList.count { eraseLine() }
            // check errors
            for message in messages where message.type == .error {
                errorCount += 1
            }
            // print finished module
            printDoneModule(name: name, index: finishedCount + 1, messages: messages)
            finishedCount += 1
            workingModuleList.removeAll { $0 == name }
            // print each working modules again
            for module in workingModuleList {
                printWorkingModule(name: module)
            }
        }
    }

    func printWorkingModule(name: String) {
        setColor(.cyan)
        print("* WORK \(name)")
        setDefaultColor()
    }

    func printDoneModule(name: String, index: Int, messages: consuming [SynthMessage]) {
        let isBad = messages.contains { $0.type == .error }
        setColor(isBad ? .red : .green)
        let message = isBad ? "FAIL" : "DONE"
        print("\(index) \(message) \(name)")

        for message in messages {
            switch message.type {
            case .info:
                setDefaultColor()
            case .error:
                setColor(.red)
            case .warning:
                setColor(.yellow)
            }
            print("  \(message)")
            printMessageStack(of: message)
            setDefaultColor()
        }
    }
}

func printMessageStack(of message: borrowing SynthMessage) {
    for frame in message.frames.reversed() {
        print("    in \(frame.function) at \(frame.lastDebugLoc)")
    }
}
