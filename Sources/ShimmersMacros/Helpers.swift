//
//  ShimmersMacros/Helpers.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

import SwiftSyntax
import SwiftSyntaxMacros

extension CodeBlockItemListSyntax {
    func toArray() -> [CodeBlockItemSyntax.Item] {
        var arr: [CodeBlockItemSyntax.Item] = []
        arr.reserveCapacity(count)
        for element in self {
            arr.append(element.item)
        }
        return arr
    }
}

extension Array where Element == CodeBlockItemSyntax.Item {
    func buildList() -> CodeBlockItemListSyntax {
        return CodeBlockItemListSyntax {
            for item in self {
                CodeBlockItemSyntax(item: item, trailingTrivia: .newline)
            }
        }
    }
}

extension Array where Element == DeclSyntax {
    func buildList() -> MemberBlockItemListSyntax {
        return MemberBlockItemListSyntax {
            for item in self {
                MemberBlockItemSyntax(decl: item)
            }
        }
    }
}

extension Array where Element == LabeledExprSyntax {
    func buildList() -> LabeledExprListSyntax {
        return LabeledExprListSyntax {
            for item in self {
                item
            }
        }
    }
}

extension Array where Element == SwitchCaseSyntax {
    func buildList() -> SwitchCaseListSyntax {
        return SwitchCaseListSyntax {
            for item in self {
                item
            }
        }
    }
}

extension Array where Element == FunctionParameterSyntax {
    func buildList() -> FunctionParameterListSyntax {
        return FunctionParameterListSyntax {
            for item in self {
                item
            }
        }
    }
}

extension Array where Element == ExprSyntax {
    func joined(by oper: String) -> ExprSyntax {
        precondition(count > 0, "Cannot join empty array")
        var expr: ExprSyntax = "(\(first!.trimmed))"
        for item in dropFirst() {
            expr = "\(expr) \(raw: oper) (\(item.trimmed))"
        }
        return expr
    }
    func descriptionJoined(by seperator: String) -> String {
        precondition(count > 0, "Cannot join empty array")
        return map { $0.trimmedDescription }.joined(separator: seperator)
    }
}

func clog2(_ value: Int) -> Int {
    precondition(value > 0, "must be positive integer")
    return Int.bitWidth - (value - 1).leadingZeroBitCount
}
