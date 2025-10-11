//
//  Shimmers/CNF Builder/CNF Builder.swift
//  shimmers-hdl
//
// This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
// SPDX-License-Identifier: MPL-2.0
//

class CNFBuidler {
    typealias SATVar = Int64

    private var clauses: Set<String> = ["1 0\n"]
    private var maxUsedValue: UInt32 = 1

    func getSATVar(of wireID: _WireID) -> SATVar {
        if wireID == false { return -1 }
        if wireID == true  { return  1 }
        let wireSeq = wireID.id >> 1
        maxUsedValue = max(maxUsedValue, wireSeq + 1)
        let varSeq = Int64(wireSeq + 1)
        if wireID.id & 1 == 0 {
            return varSeq
        } else {
            return -varSeq
        }
    }

    private func addClause(_ vars: SATVar...) {
        var clause = ""
        for v in vars.sorted() {
            clause.append("\(v) ")
        }
        clause.append("0\n")
        clauses.update(with: clause)
    }

    func addAnd(a: _WireID, b: _WireID, out: _WireID) {
        switch (a, b) {
        case (false, _), (_, false):
            assert(!out)
            return
        case (true, let x), (let x, true):
            addMatch(a: x, b: out)
            return
        default:
            break
        }

        addClause(-getSATVar(of: a), -getSATVar(of: b), getSATVar(of: out))
        addClause(getSATVar(of: a), -getSATVar(of: out))
        addClause(getSATVar(of: b), -getSATVar(of: out))
    }

    func addOr(a: _WireID, b: _WireID, out: _WireID) {
        addAnd(a: !a, b: !b, out: !out)
    }

    func addMatch(a: _WireID, b: _WireID) {
        if a == b { return }
        addClause( getSATVar(of: a), -getSATVar(of: b))
        addClause(-getSATVar(of: a),  getSATVar(of: b))
    }

    func addXor(a: _WireID, b: _WireID, out: _WireID) {
        switch (a, b) {
        case (false, let x), (let x, false):
            addMatch(a: x, b: out)
            return
        case (true, let x), (let x, true):
            addMatch(a: x, b: !out)
            return
        default:
            break
        }

        addClause(-getSATVar(of: a), -getSATVar(of: b), -getSATVar(of: out))
        addClause(-getSATVar(of: a),  getSATVar(of: b),  getSATVar(of: out))
        addClause( getSATVar(of: a), -getSATVar(of: b),  getSATVar(of: out))
        addClause( getSATVar(of: a),  getSATVar(of: b), -getSATVar(of: out))
    }

    func addMux(s: _WireID, a: _WireID, b: _WireID, out: _WireID) {
        switch (s, a, b) {
        case (true, let x, _), (false, _, let x):
            addMatch(a: x, b: out)
            return
        case (let s, let x, false):
            addAnd(a: s, b: x, out: out)
            return
        case (let s, false, let x):
            addAnd(a: !s, b: x, out: out)
            return
        case (let s, true, let x):
            addOr(a: s, b: x, out: out)
            return
        case (let s, let x, true):
            addOr(a: !s, b: x, out: out)
            return
        default: break
        }
        addClause(-getSATVar(of: a),  getSATVar(of: out), -getSATVar(of: s))
        addClause( getSATVar(of: a), -getSATVar(of: out), -getSATVar(of: s))
        addClause(-getSATVar(of: b),  getSATVar(of: out),  getSATVar(of: s))
        addClause( getSATVar(of: b), -getSATVar(of: out),  getSATVar(of: s))
    }

    func assert(_ wireID: _WireID) {
        if wireID == true { return }
        addClause(getSATVar(of: wireID))
    }

    func emitProblemCNF(newClauseList: [[_WireID]] = []) -> String {
        var newClauses: String = ""
        for clause in newClauseList {
            let clause = clause
                .map({ getSATVar(of: $0).description })
                .joined(separator: " ")
            newClauses += "\(clause) 0\n"
        }
        let clauseCount = clauses.count + newClauseList.count

        let prolog = "p cnf \(maxUsedValue + 10) \(clauseCount)\n"
        return prolog + clauses.joined() + newClauses
    }

    func emitProblemCNF(newClauseList: [[_WireID]] = [], to stream: inout TextOutputStream) {
        var newClauses: String = ""
        for clause in newClauseList {
            let clause = clause
                .map({ getSATVar(of: $0).description })
                .joined(separator: " ")
            newClauses += "\(clause) 0\n"
        }
        let clauseCount = clauses.count + newClauseList.count

        let prolog = "p cnf \(maxUsedValue + 10) \(clauseCount)\n"
        stream.write(prolog + clauses.joined() + newClauses)
    }

    func removeAll() {
        clauses.removeAll(keepingCapacity: false)
    }
}
