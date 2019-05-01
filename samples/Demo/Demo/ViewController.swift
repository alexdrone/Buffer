import UIKit
import Buffer

func ==(lhs: FooModel, rhs: FooModel) -> Bool {
  return lhs.text == rhs.text
}

struct FooModel: Diffable {
  /// The identifier used from the diffing algorithm.
  var diffIdentifier: String { return text }
  /// Simple text property.
  let text: String
}

class ViewController: UIViewController, UITableViewDelegate {
  /// A declarative TableView from Buffer.
  lazy var tableView: BufferTableView<FooModel> = {
    let tableView = BufferTableView<FooModel>()
    tableView.delegate = self
    return tableView
  }()
  /// Some dummy elements.
  lazy var elements: [ListItem<FooModel>] = {
    var elements = [ListItem<FooModel>]()
    for i in 0...100 {
      let item = ListItem(
        type: UITableViewCell.self,
        container: self.tableView,
        model: FooModel(text: ("\(i)"))) { cell, model in cell.textLabel?.text = model.text }
      elements.append(item)
    }
    return elements
  }()

  override func viewDidLayoutSubviews() {
    self.tableView.frame = self.view.bounds
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(self.tableView)
    self.tableView.elements = self.elements
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let tableView = tableView as? BufferTableView<FooModel> else { return }
    // Performs a bunch of random operations on the list.
    var newElements = tableView.elements
    let index: Int = (indexPath as NSIndexPath).row
    let element = newElements[index]
    newElements.remove(at: index)
    newElements.insert(element, at: 0)
    tableView.elements = newElements
  }
}





