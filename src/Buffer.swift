import Foundation

public protocol BufferType { }

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

public class Buffer<ElementType: Diffable>: NSObject, BufferType {

  /// The object that will get notified every time chavbcnges occures to the array.
  public weak var delegate: BufferDelegate?

  /// The elements in the array observer's buffer.
  public var currentElements: [ElementType] {
    return self.frontBuffer
  }

  /// Defines what is the maximum number of changes that you want the receiver to be notified for.
  public var diffThreshold = 300

  // If set to 'true' the LCS algorithm is run synchronously on the main thread.
  fileprivate var synchronous: Bool = false

  // The two buffers.
  fileprivate var frontBuffer = [ElementType]() {
    willSet {
      assert(Thread.isMainThread)
      self.observe(shouldObserveTrackedKeyPaths: false)
    }
    didSet {
      assert(Thread.isMainThread)
      self.observe(shouldObserveTrackedKeyPaths: true)
    }
  }
  fileprivate var backBuffer = [ElementType]()

  // Sort closure.
  fileprivate var sort: ((ElementType, ElementType) -> Bool)?

  // Filter closure.
  fileprivate var filter: ((ElementType) -> Bool)?

  // The serial operation queue for this controller.
  fileprivate let serialOperationQueue: OperationQueue = {
    let operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = 1
    return operationQueue
  }()

  fileprivate var flags = (isRefreshing: false,
                       shouldRefresh: false)

  // Used if 'Element' is KVO-compliant.
  fileprivate var trackedKeyPaths = [String]()

  public init(initialArray: [ElementType],
              sort: ((ElementType, ElementType) -> Bool)? = nil,
              filter: ((ElementType) -> Bool)? = nil) {

    self.frontBuffer = initialArray
    self.sort = sort
    self.filter = filter
  }

  deinit {
    self.observe(shouldObserveTrackedKeyPaths: false)
  }

  /// Compute the diffs between the current array and the new one passed as argument.
  public func update(
    with values: [ElementType]? = nil,
    synchronous: Bool = false,
    completion: (() -> Void)? = nil) {

    let new = values ?? self.frontBuffer

    // Should be called on the main thread.
    assert(Thread.isMainThread)

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

      let diff = Diff.diffing(oldArray: self.frontBuffer.map { $0.diffIdentifier},
                              newArray: backBuffer.map { $0.diffIdentifier }) {
        return $0 == $1
      }

      self.dispatchOnMainThread(synchronous: synchronous) { [weak self] in
        guard let `self` = self else {
          return
        }
        //swaps the buffers.
        self.frontBuffer = backBuffer

        if diff.inserts.count < self.diffThreshold && diff.deletes.count < self.diffThreshold {
          self.delegate?.buffer(willChangeContent: self)
          self.delegate?.buffer(didInsertElementsAtIndices: self,
                                indices: diff.inserts.map({ UInt($0) }))
          self.delegate?.buffer(didDeleteElementAtIndices: self,
                                indices: diff.deletes.map({ UInt($0) }))
          for move in diff.moves {
            self.delegate?.buffer(didMoveElement: self, from: UInt(move.from), to: UInt(move.to))
          }
          self.delegate?.buffer(didChangeContent: self)
        } else {
          self.delegate?.buffer(didChangeAllContent: self)
        }

        //re-rerun refresh if necessary.
        self.flags.isRefreshing = false
        if self.flags.shouldRefresh {
          self.flags.shouldRefresh = false
          self.update(with: self.backBuffer)
        }

        completion?()
      }
    }
  }

  /// This message is sent to the receiver when the value at the specified key path relative
  /// to the given object has changed.
  public override func observeValue(forKeyPath keyPath: String?,
                                              of object: Any?,
                                              change: [NSKeyValueChangeKey : Any]?,
                                              context: UnsafeMutableRawPointer?) {

    if context != &__observationContext {
      super.observeValue(forKeyPath: keyPath, of:object, change:change, context:context)
      return
    }
    if self.trackedKeyPaths.contains(keyPath!) {
      self.objectDidChangeValue(for: keyPath, in: object as AnyObject?)
    }

  }
}

// MARK: KVO Extension

extension Buffer where ElementType: AnyObject {

  /// Observe the keypaths passed as argument.
  public func trackKeyPaths(_ keypaths: [String]) {
    self.observe(shouldObserveTrackedKeyPaths: false)
    self.trackedKeyPaths = keypaths
    self.observe()
  }
}

extension Buffer {

  /// Adds or remove observations.
  /// - Note: This code is executed only when 'Element: AnyObject'.
  fileprivate func observe(shouldObserveTrackedKeyPaths: Bool = true) {
    if self.trackedKeyPaths.count == 0 {
      return
    }
    for keyPath in trackedKeyPaths {
      for item in self.frontBuffer {
        if let object = item as? NSObject {
          if shouldObserveTrackedKeyPaths {
            object.addObserver(self,
                               forKeyPath: keyPath,
                               options: NSKeyValueObservingOptions.new,
                               context: &__observationContext)

          } else {
            object.removeObserver(self, forKeyPath: keyPath)
          }
        }
      }
    }
  }

  // - Note: This code is executed only when 'Element: AnyObject'.
  fileprivate func objectDidChangeValue(for keyPath: String?, in object: AnyObject?) {
    guard let object = object else {
      return
    }
    dispatchOnMainThread {
      self.update() {
        var idx = 0
        let frontBuffer: [AnyObject] = self.frontBuffer.flatMap { $0 as AnyObject }
        for item in frontBuffer {
          if item === object { break }
          idx += 1
        }
        if idx < self.frontBuffer.count {
          self.delegate?.buffer(didChangeElementAtIndex: self, index: UInt(idx))
        }
      }
    }
  }
}

private var __observationContext: UInt8 = 0

//MARK: Dispatch Helpers

fileprivate extension Buffer {

  func dispatchOnMainThread(synchronous: Bool = false,
                            block: @escaping () -> Void) {
    if synchronous {
      assert(Thread.isMainThread)
      block()
    } else {
      if Thread.isMainThread { block()
      } else { DispatchQueue.main.async(execute: block) }
    }
  }

  func dispatchOnSerialQueue(synchronous: Bool = false,
                             block: @escaping () -> Void) {
    if synchronous {
      block()
    } else {
      self.serialOperationQueue.addOperation(){
        DispatchQueue.global().async(execute: block)
      }
    }
  }
}



