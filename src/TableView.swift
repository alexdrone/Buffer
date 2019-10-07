#if os(iOS)
  import UIKit

  open class BufferTableView<T: Diffable>: UITableView {
    /// The elements for the table view.
    open var elements = [ListItem<T>]() {
      didSet { self.adapter.buffer.update(with: self.elements) }
    }

    /// The adapter for this table view.
    open lazy var adapter: TableViewDiffAdapter<ListItem<T>> = {
      return TableViewDiffAdapter(initialElements: [ListItem<T>](), view: self)
    }()

    /// Convenience constructor.
    public convenience init() {
      self.init(frame: CGRect.zero, style: .plain)
    }

    /// Initializes and returns a table view object having the given frame and style.
    public override init(frame: CGRect, style: UITableView.Style) {
      super.init(frame: frame, style: style)
      self.rowHeight = UITableView.automaticDimension
      if #available(iOS 11, *) {
        self.estimatedRowHeight = -1
      } else {
        self.estimatedRowHeight = 64
      }
      self.adapter.useAsDataSource { tableView, item, indexPath in
        let cell = tableView.dequeueReusableCell(
          withIdentifier: item.reuseIdentifier,
          for: indexPath as IndexPath)
        item.cellConfiguration?(cell, item.model)
        return cell
      }
    }

    /// - note: Not supported.
    required public init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }

#endif
