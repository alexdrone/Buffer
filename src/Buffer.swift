import Foundation

public protocol BufferType {}

public protocol BufferDelegate: class {
  /// Notifies the receiver that the content is about to change.
  func buffer(willChangeContent buffer: BufferType)

  /// Notifies the receiver that rows were deleted.
  func buffer(didDeleteElementAtIndices buffer: BufferType, indices: [UInt])

  /// Notifies the receiver that rows were inserted.
  func buffer(didInsertElementsAtIndices buffer: BufferType, indices: [UInt])

  /// Notifies the receiver that an element has been moved to a different position.
  func buffer(didMoveElement buffer: BufferType, from: UInt, to: UInt)

  /// Notifies the receiver that the content updates has ended.
  func buffer(didChangeContent buffer: BufferType)

  /// Notifies the receiver that the content updates has ended.
  /// This callback method is called when the number of changes are too many to be
  /// handled for the UI thread - it's recommendable to just reload the whole data in this case.
  /// - Note: The 'diffThreshold' property in 'Buffer' defines what is the maximum number
  /// of changes
  /// that you want the receiver to be notified for.
  func buffer(didChangeAllContent buffer: BufferType)

  /// Called when one of the observed properties for this object changed.
  func buffer(didChangeElementAtIndex buffer: BufferType, index: UInt)
}

public class Buffer<E: Diffable>: NSObject, BufferType {
  /// The object that will get notified every time chavbcnges occures to the array.
  public weak var delegate: BufferDelegate?

  /// The elements in the array observer's buffer.
  public var currentElements: [E] {
    return self.frontBuffer
  }

  /// Defines what is the maximum number of changes that you want the receiver to be notified for.
  /// - note: If the number of changes exceeds this number, *buffer(didChangeAllContent:)* is going
  /// to be invoked instead.
  public var diffThreshold = 100

  /// If set to 'true' the LCS algorithm is run synchronously on the main thread.
  private var synchronous: Bool = false

  /// The exposed array.
  private var frontBuffer = [E]()

  /// The internal array.
  private var backBuffer = [E]()

  /// Sort closure.
  private var sort: ((E, E) -> Bool)?

  /// Filter closure.
  private var filter: ((E) -> Bool)?

  /// The serial operation queue for this controller.
  private let serialOperationQueue: OperationQueue = {
    let operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = 1
    return operationQueue
  }()

  /// Internal state flags.
  private var flags = (
    isRefreshing: false,
    shouldRefresh: false
  )

  /// Constructs a new buffer instance.
  public init(
    initialArray: [E],
    sort: ((E, E) -> Bool)? = nil,
    filter: ((E) -> Bool)? = nil
  ) {
    self.frontBuffer = initialArray
    self.sort = sort
    self.filter = filter
  }

  /// Compute the diffs between the current array and the new one passed as argument.
  public func update(
    with values: [E]? = nil,
    synchronous: Bool = false,
    completion: (() -> Void)? = nil
  ) {
    // Should be called on the main thread.
    assert(Thread.isMainThread)
    let new = values ?? self.frontBuffer
    self.backBuffer = new
    // Is already refreshing.
    if self.flags.isRefreshing {
      self.flags.shouldRefresh = true
      return
    }
    self.flags.isRefreshing = true
    self.dispatchOnSerialQueue(synchronous: synchronous) { [weak self] in
      guard let `self` = self else {
        return
      }
      var backBuffer = self.backBuffer
      // Filter and sorts (if necessary).
      if let filter = self.filter {
        backBuffer = backBuffer.filter(filter)
      }
      if let sort = self.sort {
        backBuffer = backBuffer.sorted(by: sort)
      }
      // Compute the diffing.
      let diff = Diff.diffing(
        oldArray: self.frontBuffer.map { $0.diffIdentifier },
        newArray: backBuffer.map { $0.diffIdentifier }
      ) {
        return $0 == $1
      }
      // Update the front buffer on the main thread.
      self.dispatchOnMainThread(synchronous: synchronous) { [weak self] in
        guard let `self` = self else {
          return
        }
        // Swaps the buffers.
        self.frontBuffer = backBuffer
        if diff.inserts.count < self.diffThreshold && diff.deletes.count < self.diffThreshold {
          self.delegate?.buffer(willChangeContent: self)
          self.delegate?.buffer(
            didInsertElementsAtIndices: self,
            indices: diff.inserts.map({ UInt($0) }))
          self.delegate?.buffer(
            didDeleteElementAtIndices: self,
            indices: diff.deletes.map({ UInt($0) }))
          for move in diff.moves {
            self.delegate?.buffer(didMoveElement: self, from: UInt(move.from), to: UInt(move.to))
          }
          self.delegate?.buffer(didChangeContent: self)
        } else {
          self.delegate?.buffer(didChangeAllContent: self)
        }
        // Re-rerun refresh if necessary.
        self.flags.isRefreshing = false
        if self.flags.shouldRefresh {
          self.flags.shouldRefresh = false
          self.update(with: self.backBuffer)
        }
        completion?()
      }
    }
  }
}

//MARK: Dispatch Helpers

extension Buffer {
  /// Dispatches the block passed as argument on the main thread.
  /// - parameter synchronous: If true the block is going to be called on the current call stack.
  /// - parameter block: The block that is going to be executed.
  fileprivate func dispatchOnMainThread(
    synchronous: Bool = false,
    block: @escaping () -> Void
  ) {
    if synchronous {
      assert(Thread.isMainThread)
      block()
      return
    }
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }

  /// Dispatches the block passed as argument on the ad-hoc serial queue (if necesary).
  /// - parameter synchronous: If true the block is going to be called on the current call stack.
  /// - parameter block: The block that is going to be executed.
  fileprivate func dispatchOnSerialQueue(
    synchronous: Bool = false,
    block: @escaping () -> Void
  ) {
    if synchronous {
      block()
      return
    }
    self.serialOperationQueue.addOperation {
      DispatchQueue.global().async(execute: block)
    }
  }
}
