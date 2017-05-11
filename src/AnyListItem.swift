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

public struct AnyListItem: ListItemType, Equatable {

  public var reuseIdentifier: String {
    get { return self.ref.reuseIdentifier }
    set { self.ref.reuseIdentifier = newValue }
  }
  public var uniqueIdentifier: String? {
    get { return self.ref.uniqueIdentifier }
    set { self.ref.uniqueIdentifier = newValue }
  }
  public var referenceView: ListContainerView? {
    return self.ref.referenceView
  }
  public var stateRef: Any? {
    return self.ref.stateRef
  }

  public var ref: ListItemType
  init(ref: ListItemType) {
    self.ref = ref
  }

  public func configure(cell: ListViewCell) {
    self.ref.configure(cell: cell)
  }
}

public func ==(lhs: AnyListItem, rhs: AnyListItem) -> Bool {
  return lhs.reuseIdentifier == rhs.reuseIdentifier
         && lhs.uniqueIdentifier == rhs.uniqueIdentifier
}

public func ==<Type>(lhs: ListItem<Type>, rhs: ListItem<Type>) -> Bool {
  return lhs.reuseIdentifier == rhs.reuseIdentifier && lhs.state == rhs.state
}

public protocol ListItemType {

  /** The reuse identifier for the cell passed as argument. */
  var reuseIdentifier: String { get set }

  /** The unique identifier for this item. */
  var uniqueIdentifier: String? { get set }

  /** The TableView, or the CollectionView that will own this element. */
  var referenceView: ListContainerView? { get }

  var stateRef: Any? { get }

  /** Configure the cell with the current item. */
  func configure(cell: ListViewCell)
}

public class ListItem<Type: Equatable>: Equatable, ListItemType {

  public var reuseIdentifier: String
  public var uniqueIdentifier: String?
  public let referenceView: ListContainerView?

  /** The actual item data. */
  public var state: Type
  public var stateRef: Any? {
    return self.state
  }

  public var cellConfiguration: ((ListViewCell, Type) -> Void)?

  #if os(iOS)
  public init<V: PrototypeViewCell>(
      type: V.Type,
      container: ListContainerView,
      reuseIdentifer: String = String(describing: V.self),
      id: String? = nil,
      state: Type,
      configurationClosure: ((V, Type) -> Void)? = nil) {

    // registers the prototype cell if necessary.
    if !Prototypes.isPrototypeCellRegistered(reuseIdentifer) {
      let cell = V(reuseIdentifier: reuseIdentifer)
      Prototypes.registerPrototypeCell(reuseIdentifer, cell: cell)
    }

    self.reuseIdentifier = reuseIdentifer
    if let closure = configurationClosure {
      self.cellConfiguration = { cell, type in
        return closure(cell as! V, type)
      }
    }
    self.uniqueIdentifier = id
    self.referenceView = container
    self.state = state
    self.registerReferenceView(with: type)
  }
  #endif

  public init<V: ListViewCell>(
      type: V.Type,
      container: ListContainerView? = nil,
      reuseIdentifer: String = String(describing: V.self),
      id: String? = nil,
      state: Type,
      configurationClosure: ((V, Type) -> Void)? = nil) {

    self.reuseIdentifier = reuseIdentifer
    if let closure = configurationClosure {
      self.cellConfiguration = { cell, type in
        return closure(cell as! V, type)
      }
    }
    self.uniqueIdentifier = id
    self.referenceView = container
    self.state = state
    self.registerReferenceView(with: type)
  }

  fileprivate func registerReferenceView(with cellClass: AnyClass) {
    #if os(iOS)
      if let tableView = self.referenceView as? UITableView {
        tableView.register(cellClass, forCellReuseIdentifier: self.reuseIdentifier)
      }
      if let collectionView = self.referenceView as? UICollectionView {
        collectionView.register(cellClass, forCellWithReuseIdentifier: self.reuseIdentifier)
      }
    #endif
  }

  public func configure(cell: ListViewCell) {

    self.cellConfiguration?(cell,  self.state)
  }
}
