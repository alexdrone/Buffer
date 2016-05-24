//
//  ViewController.swift
//  BufferDemo
//
//  Created by Alex Usbergo on 24/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Buffer

class ViewController: UIViewController, UITableViewDelegate {
    
    lazy var tableView: UITableView = {
       let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        return tableView
    }()
    
    lazy var elements: [String] = {
        var elements = [String]()
        for _ in 0...100 {
            elements.append(Lorem.sentences(1))
        }
        return elements
    }()
    
    lazy var adapter: TableViewDiffAdapter<String> = {
        return TableViewDiffAdapter(initialElements: self.elements, view: self.tableView)
    }()
    
    override func viewDidLayoutSubviews() {
        self.tableView.frame = self.view.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        
        self.adapter.useAsDataSource() { tableView, element, indexPath in
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
            cell.textLabel?.text = "\(element)"
            cell.textLabel?.numberOfLines = 0
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

