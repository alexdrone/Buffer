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

public protocol ListItemType: Diffable {
  /// The reuse identifier for the cell passed as argument.
  var reuseIdentifier: String { get set }
  /// The TableView, or the CollectionView that will own this element.
  var referenceView: ListContainerView? { get }
  var modelRef: Any? { get }

  /// Configure the cell with the current item.
  func configure(cell: ListViewCell)
}

public class ListItem<Type: Diffable>: ListItemType, CustomDebugStringConvertible {
  public var reuseIdentifier: String
  public var diffIdentifier: String {
    return "\(reuseIdentifier)_\(model.diffIdentifier)"
  }
  public let referenceView: ListContainerView?
  /// The actual item data.
  public var model: Type
  public var modelRef: Any? { return self.model }
  public var debugDescription: String { return self.diffIdentifier }
  public var cellConfiguration: ((ListViewCell, Type) -> Void)?

  #if os(iOS)
  public init<V: PrototypeViewCell>(
      type: V.Type,
      container: ListContainerView,
      reuseIdentifer: String = String(describing: V.self),
      model: Type,
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
    self.referenceView = container
    self.model = model
    self.registerReferenceView(with: type)
  }
  #endif

  public init<V: ListViewCell>(
      type: V.Type,
      container: ListContainerView? = nil,
      reuseIdentifer: String = String(describing: V.self),
      id: String? = nil,
      model: Type,
      configurationClosure: ((V, Type) -> Void)? = nil) {

    self.reuseIdentifier = reuseIdentifer
    if let closure = configurationClosure {
      self.cellConfiguration = { cell, type in
        return closure(cell as! V, type)
      }
    }
    self.referenceView = container
    self.model = model
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
    self.cellConfiguration?(cell,  self.model)
  }
}
