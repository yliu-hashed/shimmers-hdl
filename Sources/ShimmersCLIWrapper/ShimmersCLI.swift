//
//  ShimmersCLIWrapper/ShimmersCLI.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Shimmers
import ArgumentParser
import Foundation

public protocol GeneratorsDriverCommand {
    static var providingModules: [TopLevelGenerator.Type] { get }
}

public extension GeneratorsDriverCommand {
    typealias Command = ShimmersSynthCommandBase<Self>

    static func main() async {
        await Command.main()
    }
}

public struct ShimmersSynthCommandBase<Provider: GeneratorsDriverCommand>: AsyncParsableCommand {

    public static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "command")
    }

    @Option(
        name: [.customShort("d"), .customLong("disable")],
        help: ArgumentHelp(
            "The set of assertions to disable.",
            discussion: "Values with 'x' prefix will be interpreted as negated assertions. For example '--disable xoverflow' will disable anything that is not overflow assertions. Any other values are treated as custom assertion values.",
            valueName: "assertions"
        )
    )
    var disabledAssertionSets: [AssertionDisableSetPortion] = []

    @Flag(name: [.customLong("print-includes")],
          help: "Print include directives for generated Verilog files according to hiearchy.")
    var printIncludes: Bool = false

    @Option(name: [.customLong("kissat")],
            help: ArgumentHelp("The path to the kissat solver.", valueName: "kissat-path"))
    var kissatPath: String? = nil

    @Argument(help: "The path to the directory to write the generated verilog files.")
    var path: String

    @Argument(help: "The set of modules to generate.")
    var moduleNames: [ModuleName<Provider>]

    public init() {
        var table: [String: TopLevelGenerator.Type] = [:]
        for module in Provider.providingModules {
            if let existingModule = table[module.name] {
                fatalError("Duplicate module name provided '\(module.name)' between '\(existingModule)' and '\(module)'")
            }
            table[module.name] = module
        }
    }

    public nonisolated enum CommandError: Error, CustomStringConvertible {
        case errorsEncountered(count: Int)

        public var description: String {
            switch self {
            case .errorsEncountered(count: let count):
                return "Encountered \(count) errors."
            }
        }
    }

    public func run() async throws {
        let modules = Provider.providingModules

        var table: [String: TopLevelGenerator.Type] = [:]
        for module in modules {
            table[module.name] = module
        }

        let url = URL(fileURLWithPath: path, isDirectory: true)
        let kissatURL: URL?
        if let path = kissatPath {
            kissatURL = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            kissatURL = nil
        }

        // for a set of disabled assertions
        var assertions: AssertionSet = []
        for set in disabledAssertionSets {
            if set.include {
                assertions.formUnion(set.portion.assertions)
            } else {
                assertions.formIntersection(set.portion.assertions)
            }
        }

        let options = SynthOptions(
            kissatURL: kissatURL,
            disabledAssertions: assertions,
            printIncludes: printIncludes
        )

        let printer: ProgressPrinter = makePrinter()
        let driver = SynthDriver(directory: url, with: options)
        await driver.addNotifier { (notification) in
            Task {
                await printer.update(of: notification)
            }
        }

        for name in moduleNames {
            let moduleType = table[name.name]!
            await driver.enqueue(moduleType)
        }

        await driver.waitForAll()

        let count = await printer.errorCount

        if count > 0 {
            throw CommandError.errorsEncountered(count: count)
        }
    }
}
