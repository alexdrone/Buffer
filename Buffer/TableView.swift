//
//  BufferDiffCollectionView.swift
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

#if os(iOS)

  public class TableView<Type: Equatable>: UITableView {

    /// The elements for the table view.
    public var elements = [AnyListItem<Type>]() {
      didSet {
        self.adapter.buffer.update(self.elements)
      }
    }

    /// The adapter for this table view.
    public lazy var adapter: TableViewDiffAdapter<AnyListItem<Type>> = {
      return TableViewDiffAdapter(initialElements: [AnyListItem<Type>](), view: self)
    }()

    public convenience init() {
      self.init(frame: CGRect.zero, style: .Plain)
    }

    public override init(frame: CGRect, style: UITableViewStyle) {
      super.init(frame: frame, style: style)

      self.rowHeight = UITableViewAutomaticDimension
      self.adapter.useAsDataSource() { tableView, item, indexPath in
        let cell = tableView.dequeueReusableCellWithIdentifier(
          item.reuseIdentifier, forIndexPath: indexPath)
        item.cellConfiguration?(cell, item.state)
        return cell
      }
    }
  }

#endif