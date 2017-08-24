import UIKit
import Buffer

func ==(lhs: FooModel, rhs: FooModel) -> Bool {
  return lhs.text == rhs.text
}

struct FooModel: Diffable {
  var diffIdentifier: String {
    return text
  }
  let text: String
}

class ViewController: UIViewController, UITableViewDelegate {

  lazy var tableView: TableView<FooModel> = {
    let tableView = TableView<FooModel>()
    tableView.delegate = self
    return tableView
  }()

  lazy var elements: [ListItem<FooModel>] = {
    var elements = [ListItem<FooModel>]()
    for i in 0...100 {
      let item = ListItem(type: UITableViewCell.self,
                          container: self.tableView,
                          model: FooModel(text: ("\(i)"))) { cell, model in
                            cell.textLabel?.text = model.text
      }
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
    guard let tableView = tableView as? TableView<FooModel> else {
      return
    }
    var newElements = tableView.elements
    let index: Int = (indexPath as NSIndexPath).row
    let element = newElements[index]
    newElements.remove(at: index)
    newElements.insert(element, at: 0)
    tableView.elements = newElements
  }
}





