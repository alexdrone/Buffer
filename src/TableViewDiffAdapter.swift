#if os(iOS)
  import UIKit

  open class TableViewDiffAdapter<E: Diffable>:
    NSObject,
    AdapterType,
    UITableViewDataSource
  {

    public typealias `Type` = E
    public typealias ViewType = UITableView

    /// The buffer object.
    open fileprivate(set) var buffer: Buffer<E>

    /// The collection view owning this adapter.
    open fileprivate(set) weak var view: ViewType?

    /// Right now this only works on a single section of a tableView.
    /// If your tableView has multiple sections, though, you can just use multiple
    /// TableViewDiffAdapter, one per section, and set this value appropriately on each one.
    open var sectionIndex: Int = 0

    /// The *cellForItemAtIndexPath* block.
    fileprivate var cellForRowAtIndexPath:
      ((UITableView, E, IndexPath) -> UITableViewCell)?
      = nil

    public required init(buffer: BufferType, view: ViewType) {
      guard let buffer = buffer as? Buffer<E> else {
        fatalError()
      }
      self.buffer = buffer
      self.view = view
      super.init()
      self.buffer.delegate = self
    }

    public required init(initialElements: [E], view: ViewType) {
      self.buffer = Buffer(initialArray: initialElements)
      self.view = view
      super.init()
      self.buffer.delegate = self
    }

    /// Returns the element currently on the front buffer at the given index path.
    open func displayedElement(at index: Int) -> Type {
      return self.buffer.currentElements[index]
    }

    /// The total number of elements currently displayed.
    open func countDisplayedElements() -> Int {
      return self.buffer.currentElements.count
    }

    /// Replace the elements buffer and compute the diffs.
    /// - parameter newValues: The new values.
    /// - parameter synchronous: Wether the filter, sorting and diff should be
    /// executed synchronously or not.
    /// - parameter completion: Code that will be executed once the buffer is updated.
    open func update(
      with newValues: [E]? = nil,
      synchronous: Bool = false,
      completion: (() -> Void)? = nil
    ) {
      self.buffer.update(with: newValues, synchronous: synchronous, completion: completion)
    }

    /// Configure the TableView to use this adapter as its DataSource.
    /// - parameter automaticDimension: If you wish to use 'UITableViewAutomaticDimension'
    /// as 'rowHeight'.
    /// - parameter estimatedHeight: The estimated average height for the cells.
    /// - parameter cellForRowAtIndexPath: The closure that returns a cell for the
    /// given index path.
    open func useAsDataSource(
      _ cellForRowAtIndexPath:
        @escaping (UITableView, E, IndexPath) -> UITableViewCell
    ) {
      self.view?.dataSource = self
      self.cellForRowAtIndexPath = cellForRowAtIndexPath
    }

    /// Tells the data source to return the number of rows in a given section of a table view.
    dynamic open func tableView(
      _ tableView: UITableView,
      numberOfRowsInSection section: Int
    ) -> Int {
      return self.buffer.currentElements.count
    }

    /// Asks the data source for a cell to insert in a particular location of the table view.
    open func tableView(
      _ tableView: UITableView,
      cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
      return self.cellForRowAtIndexPath!(
        tableView,
        buffer.currentElements[(indexPath as NSIndexPath).row],
        indexPath)
    }
  }

  extension TableViewDiffAdapter: BufferDelegate {
    /// Notifies the receiver that the content is about to change.
    public func buffer(willChangeContent buffer: BufferType) {
      self.view?.beginUpdates()
    }

    /// Notifies the receiver that rows were deleted.
    public func buffer(didDeleteElementAtIndices buffer: BufferType, indices: [UInt]) {
      let deletionIndexPaths = indices.map({
        IndexPath(row: Int($0), section: self.sectionIndex)
      })
      self.view?.deleteRows(at: deletionIndexPaths, with: .fade)
    }

    /// Notifies the receiver that rows were inserted.
    public func buffer(didInsertElementsAtIndices buffer: BufferType, indices: [UInt]) {
      let insertionIndexPaths = indices.map({
        IndexPath(row: Int($0), section: self.sectionIndex)
      })
      self.view?.insertRows(at: insertionIndexPaths, with: .fade)
    }

    /// Notifies the receiver that a row got moved.
    public func buffer(didMoveElement buffer: BufferType, from: UInt, to: UInt) {
      self.view?.moveRow(
        at: IndexPath(row: Int(from), section: self.sectionIndex),
        to: IndexPath(row: Int(to), section: self.sectionIndex))
    }

    /// Notifies the receiver that the content updates has ended.
    public func buffer(didChangeContent buffer: BufferType) {
      self.view?.endUpdates()
    }

    /// Called when one of the observed properties for this object changed.
    public func buffer(didChangeElementAtIndex buffer: BufferType, index: UInt) {
      self.view?.reloadRows(
        at: [IndexPath(row: Int(index), section: self.sectionIndex)],
        with: .automatic)
    }

    /// Notifies the receiver that the content updates has ended and the whole array changed.
    public func buffer(didChangeAllContent buffer: BufferType) {
      self.view?.reloadData()
    }
  }

#endif
