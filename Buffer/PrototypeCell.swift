//
//  Cell.swift
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
  import UIKit

  public protocol PrototypeViewCell: ListViewCell {

    /// The TableView or CollectionView that owns this cell.
    var referenceView: ListContainerView? { get set }

    // /Apply the state.
    /// - Note: This is used internally from the infra to set the state.
    func applyState<T>(state: T)

    init(reuseIdentifier: String)
  }

  public class PrototypeTableViewCell<ViewType: UIView, StateType> :
  UITableViewCell, PrototypeViewCell {

    /// The wrapped view.
    public var view: ViewType!

    /// The state for this cell.
    /// - Note: This is propagated to the associted-
    public var state: StateType? {
      didSet {
        didSetStateClosure?(state)
      }
    }

    weak public var referenceView: ListContainerView?

    private var didInitializeCell = false
    private var didSetStateClosure: ((StateType?) -> Void)?

    public required init(reuseIdentifier: String) {
      super.init(style: .Default, reuseIdentifier: reuseIdentifier)
    }

    public func initializeCellIfNecessary(view: ViewType,
                                          didSetState: ((StateType?) -> Void)? = nil) {

      assert(NSThread.isMainThread())

      // make sure this happens just once.
      if self.didInitializeCell { return }
      self.didInitializeCell = true

      self.view = view
      self.contentView.addSubview(view)
      self.didSetStateClosure = didSetState
    }

    public func applyState<T>(state: T) {
      self.state = state as? StateType
    }

    /// Asks the view to calculate and return the size that best fits the specified size.
    /// - parameter size: The size for which the view should calculate its best-fitting size.
    /// - returns: A new size that fits the receiver’s subviews.
    public override func sizeThatFits(size: CGSize) -> CGSize {
      let size = view.sizeThatFits(size)
      return size
    }

    /// Returns the natural size for the receiving view, considering only properties of the
    /// view itself.
    /// - returns: A size indicating the natural size for the receiving view based on its
    /// intrinsic properties.
    public override func intrinsicContentSize() -> CGSize {
      return view.intrinsicContentSize()
    }
  }

  public class PrototypeCollectionViewCell<ViewType: UIView, StateType> :
  UICollectionViewCell, PrototypeViewCell {

    ///The wrapped view.
    public var view: ViewType!

    ///The state for this cell.
    /// - Note: This is propagated to the associted.
    public var state: StateType? {
      didSet {
        didSetStateClosure?(state)
      }
    }

    weak public var referenceView: ListContainerView?

    private var didInitializeCell = false
    private var didSetStateClosure: ((StateType?) -> Void)?

    public required init(reuseIdentifier: String) {
      super.init(frame: CGRect.zero)
    }

    public func initializeCellIfNecessary(view: ViewType,
                                          didSetState: ((StateType?) -> Void)? = nil) {

      assert(NSThread.isMainThread())

      //make sure this happens just once
      if self.didInitializeCell { return }
      self.didInitializeCell = true

      self.view = view
      self.contentView.addSubview(view)
      self.didSetStateClosure = didSetState
    }

    public func applyState<T>(state: T) {
      self.state = state as? StateType
    }

    /// Asks the view to calculate and return the size that best fits the specified size.
    /// - parameter size: The size for which the view should calculate its best-fitting size.
    /// - returns: A new size that fits the receiver’s subviews.
    public override func sizeThatFits(size: CGSize) -> CGSize {
      let size = view.sizeThatFits(size)
      return size
    }

    /// Returns the natural size for the receiving view, considering only properties of the
    /// view itself.
    /// - returns: A size indicating the natural size for the receiving view based on its
    /// intrinsic properties.
    public override func intrinsicContentSize() -> CGSize {
      return view.intrinsicContentSize()
    }
  }

  public struct Prototypes {
    private static var registeredPrototypes = [String: PrototypeViewCell]()

    ///Wether there's a prototype registered for a given reusedIdentifier.
    public static func isPrototypeCellRegistered(reuseIdentifier: String) -> Bool {
      guard let _ = Prototypes.registeredPrototypes[reuseIdentifier] else { return false }
      return true
    }

    ///Register a cell a prototype for a given reuse identifer.
    public static func registerPrototypeCell(reuseIdentifier: String, cell: PrototypeViewCell) {
      Prototypes.registeredPrototypes[reuseIdentifier] = cell
    }

    ///Computes the size for the cell registered as prototype associate to the item passed
    /// as argument.
    /// - parameter item: The target item for size calculation.
    public static func prototypeCellSize<T>(item: AnyListItem<T>) -> CGSize {
      guard let cell = Prototypes.registeredPrototypes[item.reuseIdentifier] else {
        fatalError("Unregistered prototype with reuse identifier \(item.reuseIdentifier).")
      }

      cell.applyState(item.state)
      cell.referenceView = item.referenceView
      item.cellConfiguration?(cell, item.state)

      if let cell = cell as? UIView {
        return cell.bounds.size
      } else {
        return CGSize.zero
      }
    }
  }



#endif


