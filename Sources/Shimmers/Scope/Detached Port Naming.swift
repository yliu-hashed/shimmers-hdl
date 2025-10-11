//
//  Shimmers/Scope/Detached Port Naming.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

struct NamingRequirement {
    let useLongName: Bool

    init(infos: borrowing [_DetachedPortShape], hasOtherMutability: Bool = false) {
        useLongName = infos.contains(where: \.isMutable) || hasOtherMutability
    }

    init(infos: borrowing [_DetachedPortValueInfo], hasOtherMutability: Bool = false) {
        useLongName = infos.contains(where: \.shape.isMutable) || hasOtherMutability
    }

    var inArgPrefix: String {
        useLongName ? "i_args_" : "i_"
    }

    var outArgPrefix: String {
        useLongName ? "o_args_" : "o_"
    }

    var outRetName: String {
        useLongName ? "o_rets" : "o"
    }
}
