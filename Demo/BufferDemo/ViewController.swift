//
//  ViewController.swift
//  BufferDemo
//
//  Created by Alex Usbergo on 24/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Buffer

func ==(lhs: FooModel, rhs: FooModel) -> Bool {
    return lhs.text == rhs.text
}

struct FooModel: Equatable {
    let text: String
}



class ViewController: UIViewController, UITableViewDelegate {
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        return tableView
    }()
    
    lazy var elements: [AnyListItem<FooModel>] = {
        var elements = [AnyListItem<FooModel>]()
        for _ in 0...100 {
            let item = AnyListItem(type: UITableViewCell.self, referenceView: self.tableView, state: FooModel(text: (Lorem.sentences(1)))) { cell, state in
                guard let cell = cell as? UITableViewCell else { return }
                cell.textLabel?.text = state.text
            }
            elements.append(item)
        }
        return elements
    }()

    lazy var adapter: TableViewDiffAdapter<AnyListItem<FooModel>> = {
        return TableViewDiffAdapter(initialElements: self.elements, view: self.tableView)
    }()
    
    override func viewDidLayoutSubviews() {
        self.tableView.frame = self.view.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        
        self.adapter.useAsDataSource() { tableView, element, indexPath in
            let cell = tableView.dequeueReusableCellWithIdentifier(element.reuseIdentifier, forIndexPath: indexPath)
            element.cellConfiguration?(cell, element.state)
            return cell
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var elements = adapter.bufferDiff.elements
        elements.removeAtIndex(indexPath.row)
        adapter.bufferDiff.refresh(elements)
    }
}


