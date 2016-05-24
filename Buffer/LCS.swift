//
//  LCS.swift
//  BufferDiff
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  Originally created by Jack Flintermann on 3/14/15.
//  Forked from github.com/jflinter/Dwifft
//  Copyright (c) 2015 jflinter. All rights reserved.

import Foundation

public struct Diff<Type> {
    public let results: [DiffStep<Type>]
    public var insertions: [DiffStep<Type>] {
        return results.filter({ $0.isInsertion }).sort { $0.idx < $1.idx }
    }
    public var deletions: [DiffStep<Type>] {
        return results.filter({ !$0.isInsertion }).sort { $0.idx > $1.idx }
    }
    public func reversed() -> Diff<Type> {
        let reversedResults = self.results.reverse().map { (result: DiffStep<Type>) -> DiffStep<Type> in
            switch result {
            case .Insert(let i, let j): return .Delete(i, j)
            case .Delete(let i, let j): return .Insert(i, j)
            }
        }
        return Diff<Type>(results: reversedResults)
    }
}
public func +<Type> (left: Diff<Type>, right: DiffStep<Type>) -> Diff<Type> {
    return Diff<Type>(results: left.results + [right])
}

/// These get returned from calls to Array.diff(). 
/// They represent insertions or deletions that need to happen to transform array A into array A.
public enum DiffStep<Type>  {
    case Insert(Int, Type)
    case Delete(Int, Type)
    var isInsertion: Bool {
        switch(self) {
        case .Insert: return true
        case .Delete: return false
        }
    }
    public var idx: Int {
        switch(self) {
        case .Insert(let i, _): return i
        case .Delete(let i, _): return i
        }
    }
    public var value: Type {
        switch(self) {
        case .Insert(let j): return j.1
        case .Delete(let j): return j.1
        }
    }
}

private struct MemoizedSequenceComparison<Type: Equatable> {
    private static func buildTable(x: [Type], _ y: [Type], _ n: Int, _ m: Int) -> [[Int]] {
        var table = Array(count: n + 1, repeatedValue: Array(count: m + 1, repeatedValue: 0))
        for i in 0...n {
            for j in 0...m {
                if (i == 0 || j == 0) {
                    table[i][j] = 0
                }
                else if x[i-1] == y[j-1] {
                    table[i][j] = table[i-1][j-1] + 1
                } else {
                    table[i][j] = max(table[i-1][j], table[i][j-1])
                }
            }
        }
        return table
    }
}

public extension Array where Element: Equatable {
    
    /// Returns the sequence of ArrayDiffResults required to transform one array into another.
    public func diff(other: [Element]) -> Diff<Element> {
        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        return Array.diffFromIndices(table, self, other, self.count, other.count)
    }
    
    /// Walks back through the generated table to generate the diff.
    private static func diffFromIndices(table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> Diff<Element> {
        
        if i == 0 && j == 0 {
            return Diff<Element>(results: [])
        } else if i == 0 {
            return diffFromIndices(table, x, y, i, j-1) + DiffStep.Insert(j-1, y[j-1])
        } else if j == 0 {
            return diffFromIndices(table, x, y, i - 1, j) + DiffStep.Delete(i-1, x[i-1])
        } else if table[i][j] == table[i][j-1] {
            return diffFromIndices(table, x, y, i, j-1) + DiffStep.Insert(j-1, y[j-1])
        } else if table[i][j] == table[i-1][j] {
            return diffFromIndices(table, x, y, i - 1, j) + DiffStep.Delete(i-1, x[i-1])
        } else {
            return diffFromIndices(table, x, y, i-1, j-1)
        }
    }
    
    /// Applies a generated diff to an array. The following should always be true:
    /// Given x: [T], y: [T], x.apply(x.diff(y)) == y
    private func apply(diff: Diff<Element>) -> Array<Element> {
        var copy = self
        for result in diff.deletions {
            copy.removeAtIndex(result.idx)
        }
        for result in diff.insertions {
            copy.insert(result.value, atIndex: result.idx)
        }
        return copy
    }
}

public extension Array where Element: Equatable {
    
    /// Returns the longest common subsequence between two arrays.
    public func LCS(other: [Element]) -> [Element] {
        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        return Array.lcsFromIndices(table, self, other, self.count, other.count)
    }
    
    /// Walks back through the generated table to generate the LCS.
    private static func lcsFromIndices(table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> [Element] {
        if i == 0 && j == 0 {
            return []
        } else if i == 0 {
            return lcsFromIndices(table, x, y, i, j - 1)
        } else if j == 0 {
            return lcsFromIndices(table, x, y, i - 1, j)
        } else if x[i-1] == y[j-1] {
            return lcsFromIndices(table, x, y, i - 1, j - 1) + [x[i - 1]]
        } else if table[i-1][j] > table[i][j-1] {
            return lcsFromIndices(table, x, y, i - 1, j)
        } else {
            return lcsFromIndices(table, x, y, i, j - 1)
        }
    }
}
