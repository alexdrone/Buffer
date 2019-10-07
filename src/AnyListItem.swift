import Foundation

public protocol ListContainerView: class {}
public protocol ListViewCell: class {}

#if os(iOS)
  import UIKit
  extension UITableView: ListContainerView {}
  extension UICollectionView: ListContainerView {}
  extension UITableViewCell: ListViewCell {}
  extension UICollectionViewCell: ListViewCell {}
#endif

public protocol ListItemType: Diffable {
  /// The reuse identifier for the cell passed as argument.
  var reuseIdentifier: String { get set }

  /// The TableView, or the CollectionView that will own this element.
  var referenceView: ListContainerView? { get }

  /// A opaque pointer to the model associated to this row.
  var modelRef: Any? { get }

  /// Configure the cell with the current item.
  func configure(cell: ListViewCell)
}

public class ListItem<T: Diffable>: ListItemType, CustomDebugStringConvertible {
  /// The cell reuse identifier.
  public var reuseIdentifier: String

  /// The unique identifier (used for the diffing algorithm).
  public var diffIdentifier: String { return "\(reuseIdentifier)_\(model.diffIdentifier)" }

  /// The *UICollectionView/UITableView* associated to this item.
  public weak var referenceView: ListContainerView?

  /// The actual model object.
  public var model: T

  /// A opaque pointer to the model associated to this row.
  public var modelRef: Any? { return self.model }

  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String { return self.diffIdentifier }

  /// The configuration block applied to the target cell.
  public var cellConfiguration: ((ListViewCell, T) -> Void)?

  #if os(iOS)
    public init<V: PrototypeViewCell>(
      type: V.Type,
      container: ListContainerView,
      reuseIdentifer: String = String(describing: V.self),
      model: T,
      configurationClosure: ((V, T) -> Void)? = nil
    ) {
      // Registers the prototype cell if necessary.
      if !Prototypes.isPrototypeCellRegistered(reuseIdentifer) {
        let cell = V(reuseIdentifier: reuseIdentifer)
        Prototypes.registerPrototypeCell(reuseIdentifer, cell: cell)
      }
      self.reuseIdentifier = reuseIdentifer
      if let closure = configurationClosure {
        self.cellConfiguration = { cell, type in return closure(cell as! V, type) }
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
    model: T,
    configurationClosure: ((V, T) -> Void)? = nil
  ) {
    self.reuseIdentifier = reuseIdentifer
    if let closure = configurationClosure {
      self.cellConfiguration = { cell, type in return closure(cell as! V, type) }
    }
    self.referenceView = container
    self.model = model
    self.registerReferenceView(with: type)
  }

  private func registerReferenceView(with cellClass: AnyClass) {
    #if os(iOS)
      if let tableView = self.referenceView as? UITableView {
        tableView.register(cellClass, forCellReuseIdentifier: self.reuseIdentifier)
      }
      if let collectionView = self.referenceView as? UICollectionView {
        collectionView.register(cellClass, forCellWithReuseIdentifier: self.reuseIdentifier)
      }
    #endif
  }

  /// Bind the cell passed as argument to this data item.
  public func configure(cell: ListViewCell) {
    self.cellConfiguration?(cell, self.model)
  }
}
