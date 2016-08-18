//
//  AnyListItemType.swift
//  BufferDiff
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

public protocol ListContainerView: class { }
public protocol ListViewCell: class { }

#if os(iOS)
  import UIKit
  extension UITableView: ListContainerView { }
  extension UICollectionView: ListContainerView { }
  extension UITableViewCell: ListViewCell { }
  extension UICollectionViewCell: ListViewCell { }
#endif

public func ==<Type>(lhs: AnyListItem<Type>, rhs: AnyListItem<Type>) -> Bool {
  return lhs.reuseIdentifier == rhs.reuseIdentifier && lhs.state == rhs.state
}

public struct AnyListItem<Type: Equatable>: Equatable {

  ///The reuse identifier for the cell passed as argument.
  public var reuseIdentifier: String

  ///The actual item data.
  public var state: Type

  ///The TableView, or the CollectionView that will own this element.
  public let referenceView: ListContainerView?

  public var cellConfiguration: ((ListViewCell, Type) -> Void)?

  #if os(iOS)
  public init<V: PrototypeViewCell>(type: V.Type,
              referenceView: ListContainerView,
              reuseIdentifer: String = String(V.self),
              state: Type,
              configurationClosure: ((ListViewCell, Type) -> Void)? = nil) {

    //registers the prototype cell if necessary.
    if !Prototypes.isPrototypeCellRegistered(reuseIdentifer) {
      let cell = V(reuseIdentifier: reuseIdentifer)
      Prototypes.registerPrototypeCell(reuseIdentifer, cell: cell)
    }

    self.reuseIdentifier = reuseIdentifer
    self.cellConfiguration = configurationClosure
    self.referenceView = referenceView
    self.state = state
    self.configureRefenceView(type)
  }
  #endif

  public init<V: ListViewCell>(type: V.Type,
              referenceView: ListContainerView? = nil,
              reuseIdentifer: String = String(V.self),
              state: Type,
              configurationClosure: ((ListViewCell, Type) -> Void)? = nil) {

    self.reuseIdentifier = reuseIdentifer
    self.cellConfiguration = configurationClosure
    self.referenceView = referenceView
    self.state = state
    self.configureRefenceView(type)
  }

  private func configureRefenceView(cellClass: AnyClass) {
    #if os(iOS)
      if let tableView = self.referenceView as? UITableView {
        tableView.registerClass(cellClass,
                                forCellReuseIdentifier: self.reuseIdentifier)
      }
      if let collectionView = self.referenceView as? UICollectionView {
        collectionView.registerClass(cellClass,
                                     forCellWithReuseIdentifier: self.reuseIdentifier)
      }
    #endif
  }
}