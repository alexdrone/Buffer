#if os(iOS)
  import UIKit

  public protocol PrototypeViewCell: ListViewCell {
    /// The TableView or CollectionView that owns this cell.
    var referenceView: ListContainerView? { get set }

    /// Apply the model.
    /// - Note: This is used internally from the infra to set the model.
    func applyModel(_ model: Any?)

    /// Constructor.
    init(reuseIdentifier: String)
  }

  open class PrototypeTableViewCell: UITableViewCell, PrototypeViewCell {
    /// The wrapped view.
    open var view: UIView!

    /// The associated model.
    open var model: Any? {
      didSet { didSetModelClosure?(model) }
    }

    /// The *UICollectionView/UITableView* for this prototype cell.
    open weak var referenceView: ListContainerView?

    /// Internal state.
    fileprivate var didInitializeCell = false

    fileprivate var didSetModelClosure: ((Any?) -> Void)?

    public required init(reuseIdentifier: String) {
      super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    open func initializeCellIfNecessary(
      _ view: UIView,
      didSetModel: ((Any?) -> Void)? = nil
    ) {
      assert(Thread.isMainThread)
      // make sure this happens just once.
      if self.didInitializeCell { return }
      self.didInitializeCell = true

      self.view = view
      self.contentView.addSubview(view)
      self.didSetModelClosure = didSetModel
    }

    open func applyModel(_ model: Any?) {
      guard let model = model else { return }
      self.model = model
    }

    /// Asks the view to calculate and return the size that best fits the specified size.
    /// - parameter size: The size for which the view should calculate its best-fitting size.
    /// - returns: A new size that fits the receiver’s subviews.
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
      let size = view.sizeThatFits(size)
      return size
    }

    /// Returns the natural size for the receiving view, considering only properties of the
    /// view itself.
    /// - returns: A size indicating the natural size for the receiving view based on its
    /// intrinsic properties.
    open override var intrinsicContentSize: CGSize {
      return view.intrinsicContentSize
    }
  }

  open class PrototypeCollectionViewCell: UICollectionViewCell, PrototypeViewCell {
    ///The wrapped view.
    open var view: UIView!

    ///The model for this cell.
    /// - Note: This is propagated to the associted.
    open var model: Any? {
      didSet { didSetModelClosure?(model) }
    }

    /// The *UICollectionView/UITableView* for this prototype cell.
    weak open var referenceView: ListContainerView?

    /// Internal state.
    fileprivate var didInitializeCell = false

    fileprivate var didSetModelClosure: ((Any?) -> Void)?

    public required init(reuseIdentifier: String) {
      super.init(frame: CGRect.zero)
    }

    required public init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    open func initializeCellIfNecessary(
      _ view: UIView,
      didSetModel: ((Any?) -> Void)? = nil
    ) {
      assert(Thread.isMainThread)
      // make sure this happens just once
      if self.didInitializeCell { return }
      self.didInitializeCell = true
      self.view = view
      self.contentView.addSubview(view)
      self.didSetModelClosure = didSetModel
    }

    open func applyModel(_ model: Any?) {
      self.model = model
    }

    /// Asks the view to calculate and return the size that best fits the specified size.
    /// - parameter size: The size for which the view should calculate its best-fitting size.
    /// - returns: A new size that fits the receiver’s subviews.
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
      let size = view.sizeThatFits(size)
      return size
    }

    /// Returns the natural size for the receiving view, considering only properties of the
    /// view itself.
    /// - returns: A size indicating the natural size for the receiving view based on its
    /// intrinsic properties.
    open override var intrinsicContentSize: CGSize {
      return view.intrinsicContentSize
    }
  }

  public enum Prototypes {
    fileprivate static var registeredPrototypes = [String: PrototypeViewCell]()

    /// Wether there's a prototype registered for a given reusedIdentifier.
    public static func isPrototypeCellRegistered(_ reuseIdentifier: String) -> Bool {
      guard let _ = Prototypes.registeredPrototypes[reuseIdentifier] else { return false }
      return true
    }

    /// Register a cell a prototype for a given reuse identifer.
    public static func registerPrototypeCell(_ reuseIdentifier: String, cell: PrototypeViewCell) {
      Prototypes.registeredPrototypes[reuseIdentifier] = cell
    }

    /// Computes the size for the cell registered as prototype associate to the item passed
    /// as argument.
    /// - parameter item: The target item for size calculation.
    public static func prototypeCellSize(_ item: ListItemType) -> CGSize {
      guard let cell = Prototypes.registeredPrototypes[item.reuseIdentifier] else {
        fatalError("Unregistered prototype with reuse identifier \(item.reuseIdentifier).")
      }
      cell.applyModel(item.modelRef)
      cell.referenceView = item.referenceView
      item.configure(cell: cell)
      if let cell = cell as? UIView {
        return cell.bounds.size
      } else {
        return CGSize.zero
      }
    }
  }

#endif
