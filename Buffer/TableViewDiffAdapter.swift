//
//  Adapters.swift
//  BufferDiff
//
//  Created by Alex Usbergo on 02/05/16.
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
    import UIKit

    public class TableViewDiffAdapter<ElementType: Equatable>: NSObject, UITableViewDataSource {
        
        public typealias Type = ElementType
        public typealias ViewType = UITableView
        
        public private(set) var bufferDiff: BufferDiff<ElementType>
        
        ///All the elements that are currently exposed from the adapter
        public var elements: [ElementType] {
            get {
                return self.bufferDiff.elements
            }
            set {
                self.bufferDiff.refresh(newValue)
            }
        }
        
        public private(set) weak var view: ViewType?
        
        
        ///Right now this only works on a single section of a tableView.
        ///If your tableView has multiple sections, though, you can just use multiple
        ///TableViewDiffAdapter, one per section, and set this value appropriately on each one.
        public var sectionIndex: Int = 0
        
        public required init(bufferDiff: BufferDiffType, view: ViewType) {
            guard let bufferDiff = bufferDiff as? BufferDiff<ElementType> else {
                fatalError()
            }
            self.bufferDiff = bufferDiff
            self.view = view
            super.init()
            self.bufferDiff.delegate = self
        }
        
        public required init(initialElements: [ElementType], view: ViewType) {
            self.bufferDiff = BufferDiff(initialArray: initialElements)
            self.view = view
            super.init()
            self.bufferDiff.delegate = self
        }
        
        private var cellForRowAtIndexPath: ((UITableView, ElementType, NSIndexPath) -> UITableViewCell)? = nil
        
        ///Configure the TableView to use this adapter as its DataSource.
        /// - parameter automaticDimension: If you wish to use 'UITableViewAutomaticDimension' as 'rowHeight'.
        /// - parameter estimatedHeight: The estimated average height for the cells.
        /// - parameter cellForRowAtIndexPath: The closure that returns a cell for the given index path.
        public func useAsDataSource(cellForRowAtIndexPath: (UITableView, ElementType, NSIndexPath) -> UITableViewCell) {
            self.view?.dataSource = self
            self.cellForRowAtIndexPath = cellForRowAtIndexPath
        }
        
        /// Tells the data source to return the number of rows in a given section of a table view.
        dynamic public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return self.bufferDiff.elements.count
        }
        
        /// Asks the data source for a cell to insert in a particular location of the table view.
        public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            return self.cellForRowAtIndexPath!(tableView, self.bufferDiff.elements[indexPath.row], indexPath)
        }
    }
    
    extension TableViewDiffAdapter: BufferDiffDelegate {
        
        ///Notifies the receiver that the content is about to change
        public func bufferDiffWillChangeContent(bufferDiff: BufferDiffType) {
            self.view?.beginUpdates()
        }
        
        ///Notifies the receiver that rows were deleted.
        public func bufferDiffDidDeleteElementAtIndices(bufferDiff: BufferDiffType, indices: [UInt]) {
            let deletionIndexPaths = indices.map({ NSIndexPath(forRow: Int($0), inSection: self.sectionIndex) })
            self.view?.deleteRowsAtIndexPaths(deletionIndexPaths, withRowAnimation: .Automatic)
        }
        
        ///Notifies the receiver that rows were inserted.
        public func bufferDiffDidInsertElementsAtIndices(bufferDiff: BufferDiffType, indices: [UInt]) {
            let insertionIndexPaths = indices.map({ NSIndexPath(forRow: Int($0), inSection: self.sectionIndex) })
            self.view?.insertRowsAtIndexPaths(insertionIndexPaths, withRowAnimation: .Automatic)
        }
        
        ///Notifies the receiver that the content updates has ended.
        public func bufferDiffDidChangeContent(bufferDiff: BufferDiffType) {
            self.view?.endUpdates()
        }
        
        ///Called when one of the observed properties for this object changed
        public func bufferDiffDidChangeElementAtIndex(bufferDiff: BufferDiffType, index: UInt) {
            self.view?.reloadRowsAtIndexPaths([NSIndexPath(forRow: Int(index), inSection: self.sectionIndex)], withRowAnimation: .Automatic)
        }
        
        ///Notifies the receiver that the content updates has ended and the whole array changed.
        public func bufferDiffDidChangeAllContent(bufferDiff: BufferDiffType) {
            self.view?.reloadData()
            self.view?.endUpdates()
        }
    }

#endif
