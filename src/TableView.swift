#if os(iOS)
import UIKit

open class TableView<Type: Diffable>: UITableView {

  /** The elements for the table view. */
  open var elements = [ListItem<Type>]() {
    didSet {
      self.adapter.buffer.update(with: self.elements)
    }
  }

  /** The adapter for this table view. */
  open lazy var adapter: TableViewDiffAdapter<ListItem<Type>> = {
    return TableViewDiffAdapter(initialElements: [ListItem<Type>](), view: self)
  }()

  public convenience init() {
    self.init(frame: CGRect.zero, style: .plain)
  }

  public override init(frame: CGRect, style: UITableViewStyle) {
    super.init(frame: frame, style: style)

    self.rowHeight = UITableViewAutomaticDimension
    if #available(iOS 11, *) {
      self.estimatedRowHeight = -1
    } else {
      self.estimatedRowHeight = 64
    }
    self.adapter.useAsDataSource() { tableView, item, indexPath in
      let cell = tableView.dequeueReusableCell(
        withIdentifier: item.reuseIdentifier, for: indexPath as IndexPath)
      item.cellConfiguration?(cell, item.model)
      return cell
    }
  }

  required public init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
}

#endif
