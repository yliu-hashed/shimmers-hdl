//
//  ShimmersCLIWrapper/Module Name.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import Shimmers
import ArgumentParser

struct ModuleName<Provider: GeneratorsDriverCommand>: ExpressibleByArgument {
    var name: String

    init?(argument: String) {
        let allValues = Self.allValueStrings
        guard allValues.contains(argument) else { return nil }
        name = argument
    }

    static var allValueStrings : [String] {
        var result: Set<String> = []
        for module in Provider.providingModules {
            result.insert(module.name)
        }
        return Array(result)
    }

    var defaultValueDescription: String {
        return name
    }
}

