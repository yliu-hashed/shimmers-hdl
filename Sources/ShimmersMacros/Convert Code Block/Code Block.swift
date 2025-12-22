//
//  ShimmersMacros/Convert Code Block/Code Block.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct CodeListDebugInfo {
    var name: String
    var entry: AbstractSourceLocation?
}

func convertFullCodeList(
    for list: CodeBlockItemListSyntax,
    returnRefType: TypeSyntax?,
    isMutating: Bool,
    at loc: CodeListDebugInfo,
    in context: some MacroExpansionContext
) throws -> CodeBlockItemListSyntax {

    var items: [CodeBlockItemSyntax.Item] = []

    items.append(.decl("let _frame = _pushDebugFrame(file: \(loc.entry?.file), line: \(loc.entry?.line), function: \"\(raw: loc.name)\")"))
    items.append(.expr("_ = _frame"))
    items.append(.stmt("defer {_frame.pop()}"))

    // mutating function
    if isMutating {
        items.append(.expr("_virtualize()"))
    }

    // function return
    items.append(.decl("@_Local var _ret: BoolRef = false"))
    if let returnRefType = returnRefType {
        items.append(.decl("@_Local var _retVal: \(returnRefType.trimmed)"))
    }

    let unique = UniqueGenerator()

    let info = CodeBlockInfo(implicitConds: [.ret], unique: unique)

    try addCodeList(
        referencing: ArraySlice(list.toArray()), into: &items,
        info: info, mayConflictDecl: false, in: context
    )

    if isMutating {
        items.append(.expr("_devirtualize()"))
    }
    // function return
    if returnRefType != nil {
        items.append(.stmt("return _retVal"))
    }
    return items.buildList()
}

class UniqueGenerator {
    private var last: UInt64 = 0
    func get() -> UInt64 {
        last += 1
        return last
    }
}

struct CodeBlockInfo {
    var implicitConds: Set<ImplicitCondition>
    var recentBrk: String? = nil
    var recentCnt: String? = nil

    var recentLabel: TokenSyntax? = nil
    var unique: UniqueGenerator

    var implicitCondExprs: [ExprSyntax] {
        implicitConds.map(\.expr)
    }

    func withNew(implicitConds new: Set<ImplicitCondition> = [], loopID: String? = nil) -> CodeBlockInfo {
        var me = self
        me.implicitConds = new.union(me.implicitConds)
        me.recentLabel = nil
        me.recentBrk = loopID ?? me.recentBrk
        me.recentCnt = loopID ?? me.recentCnt
        return me
    }

    func withNew(implicitConds new: Set<ImplicitCondition> = [], switchID: String? = nil) -> CodeBlockInfo {
        var me = self
        me.implicitConds = new.union(me.implicitConds)
        me.recentLabel = nil
        me.recentBrk = switchID ?? me.recentBrk
        return me
    }

    func withRecentLabel(_ label: TokenSyntax) -> CodeBlockInfo {
        var me = self
        me.recentLabel = label
        return me
    }
}

enum ImplicitCondition: Hashable {
    case ret
    case brk(label: String)
    case cnt(label: String)

    var expr: ExprSyntax {
        switch self {
        case .ret:
            return "!_ret"
        case .brk(let label):
            return "!_brk\(raw: label)"
        case .cnt(let label):
            return "!_cnt\(raw: label)"
        }
    }
}


