//
//  BufferCollectionView.swift
//  Buffer
//
//  Created by Alex Usbergo on 25/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

#if os(iOS)

    public class TableView<Type: Equatable>: UITableView {
        
        ///The elements for the table view.
        public var elements = [AnyListItem<Type>]() {
            didSet {
                self.adapter.bufferDiff.refresh(self.elements)
            }
        }

        ///The adapter for this table view.
        public lazy var adapter: TableViewDiffAdapter<AnyListItem<Type>> = {
           return TableViewDiffAdapter(initialElements: [AnyListItem<Type>](), view: self)
        }()
        
        public convenience init() {
            self.init(frame: CGRect.zero, style: .Plain)
        }
        
        public override init(frame: CGRect, style: UITableViewStyle) {
            super.init(frame: frame, style: style)
            
            self.rowHeight = UITableViewAutomaticDimension
            self.adapter.useAsDataSource() { tableView, item, indexPath in
                let cell = tableView.dequeueReusableCellWithIdentifier(item.reuseIdentifier, forIndexPath: indexPath)
                item.cellConfiguration?(cell, item.state)
                return cell
            }
        }
    }
    
#endif