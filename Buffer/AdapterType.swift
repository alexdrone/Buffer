//
//  AdapterType.swift
//  Buffer
//
//  Copyright (c) 2016 Alex Usbergo.
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


import Foundation

public protocol AdapterType {

  associatedtype `Type`
  associatedtype ViewType

  ///Returns the element currently on the front buffer at the given index path.
  func displayedElement(at index: Int) -> Type

  ///The total number of elements currently displayed.
  func countDisplayedElements() -> Int

  ///Replace the elements buffer and compute the diffs.
  /// - parameter newValues: The new values.
  /// - parameter synchronous: Wether the filter, sorting and diff should be executed
  /// synchronously or not.
  /// - parameter completion: Code that will be executed once the buffer is updated.
  func update(with values: [Type]?, synchronous: Bool, completion: ((Void) -> Void)?)

  ///The section index associated with this adapter.
  var sectionIndex: Int { get set }

  ///The target view.
  var view: ViewType? { get }

  init(buffer: BufferType, view: ViewType)
  init(initialElements: [Type], view: ViewType)
}
