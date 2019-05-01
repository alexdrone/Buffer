
# Buffer [![Swift](https://img.shields.io/badge/swift-5-orange.svg?style=flat)](#) [![Platform](https://img.shields.io/badge/platform-iOS|macOS-lightgrey.svg?style=flat)](#) [![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://opensource.org/licenses/MIT)

<img src="https://raw.githubusercontent.com/alexdrone/Buffer/master/docs/logo_small.png" width=150 alt="Buffer" align=right />

Swift μ-framework for efficient array diffs, collection observation and data source implementation.

[C++11 port here](https://github.com/alexdrone/libbuffer)

### Installation

```bash
cd {PROJECT_ROOT_DIRECTORY}
curl "https://raw.githubusercontent.com/alexdrone/Buffer/master/bin/dist.zip" > dist.zip && unzip dist.zip && rm dist.zip;
```

Drag `Buffer.framework` in your project and add it as an embedded binary.

If you use [xcodegen](https://github.com/yonaskolb/XcodeGen) add the framework to your *project.yml* like so:

```yaml
targets:
  YOUR_APP_TARGET:
    ...
    dependencies:
      - framework: PATH/TO/YOUR/DEPS/Buffer.framework
```

## Installation with CocoaPods/Carthage (deprecated)

If you are using **CocoaPods**:


Add the following to your [Podfile](https://guides.cocoapods.org/using/the-podfile.html):

```ruby
pod 'Buffer'
```

If you are using **Carthage**:


To install Carthage, run (using Homebrew):

```bash
$ brew update
$ brew install carthage
```


Then add the following line to your `Cartfile`:

```
github "alexdrone/Buffer" "master"    
```


# Getting started

Buffer is designed to be very granular and has APIs with very different degrees of abstraction.


### Managing a collection with Buffer

You can initialize and use **Buffer** in the following way.

```swift

import Buffer

class MyClass: BufferDelegate {

  lazy var buffer: Buffer<Foo> = {
    // The `sort` and the `filter` closure are optional - they are a convenient way to map the src array.
    let buffer = Buffer(initialArray: self.elements, sort: { $0.bar > $1.bar }, filter: { $0.isBaz })
    buffer.delegate = self
  }()

  var elements: [Foo] = [Foo]() {
    didSet {
      // When the elements are changed the buffer object will compute the difference and trigger
      // the invocation of the delegate methods.
      // The `synchronous` and `completion` arguments are optional.
      self.buffer.update(with: newValues, synchronous: false, completion: nil)
    }
  }


  //These methods will be called when the buffer has changedd.

  public func buffer(willChangeContent buffer: BufferType) {
    //e.g. self.tableView?.beginUpdates()

  }

  public func buffer(didDeleteElementAtIndices buffer: BufferType, indices: [UInt]) {
    //e.g. Remove rows from a tableview
  }

  public func buffer(didInsertElementsAtIndices buffer: BufferType, indices: [UInt]) {
  }

  public func buffer(didChangeContent buffer: BufferType) {
  }

  public func buffer(didChangeElementAtIndex buffer: BufferType, index: UInt) {
  }

  public func buffer(didMoveElement buffer: BufferType, from: UInt, to: UInt) {
  }

  public func buffer(didChangeAllContent buffer: BufferType) {
  }
}

```

### Built-in UITableView and UICollectionView adapter

One of the main use cases for **Buffer** is probably to apply changes to a TableView or a CollectionView.
**Buffer** provides 2 adapter classes that implement the `BufferDelegate` protocol and automatically perform the required
changes on the target tableview/collectionview when required.

```swift

import Buffer

class MyClass: UITableViewController {

  lazy var buffer: Buffer<Foo> = {
    // The `sort` and the `filter` closure are optional - they are convenient way to map the src array.
    let buffer = Buffer(initialArray: self.elements, sort: { $0.bar > $1.bar }, filter: { $0.isBaz })
    buffer.delegate = self
  }()

  var elements: [Foo] = [Foo]() {
    didSet {
      // When the elements are changed the buffer object will compute the difference and trigger
      // the invocation of the delegate methods.
      // The `synchronous` and `completion` arguments are optional.
      self.buffer.update(with: newValues, synchronous: false, completion: nil)
    }
  }

  let adapter: TableViewDiffAdapter<Foo>!

  init() {
    super.init()
    self.adapter = TableViewDiffAdapter(buffer: self.buffer, view: self.tableView)

    // Additionaly you can let the adapter be the datasource for your table view by passing a cell
    // configuration closure to the adpater.
    adapter.useAsDataSource { (tableView, object, indexPath) -> UITableViewCell in
      let cell = tableView.dequeueReusableCellWithIdentifier("MyCell")
	  			cell?.textLabel?.text = object.foo
	  			return cell
    }
  }

}


```

### Component-Oriented TableView

Another convenient way to use **Buffer** is through the `Buffer.TableView` class.
This abstraction allows for the tableView to reconfigure itself when its state (the elements) change.

```swift

import Buffer

class ViewController: UIViewController {

  lazy var tableView: TableView<FooModel> = {
    let tableView = TableView<FooModel>()
    return tableView
  }()

  lazy var elements: [ListItem<FooModel>] = {
    var elements = [ListItem<FooModel>]()
    for _ in 0...100 {
      // AnyListItem wraps the data and the configuration for every row in the tableview.
      let item = ListItem(type: UITableViewCell.self,
                          container: self.tableView,
                          model: FooModel(text: "Foo"))) {
        cell, model in
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
}


```

Check the demo out to learn more about Buffer.

### Credits

- Diff algorithm from IGListKit/IGListDiff
	* [IGListKit original ObjC++ implementation](https://github.com/Instagram/IGListKit)
	* [ListDiff Swift port](https://github.com/lxcid/ListDiff)
