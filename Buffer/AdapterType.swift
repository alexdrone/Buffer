//
//  AdapterType.swift
//  Buffer
//
//  Created by Alex Usbergo on 24/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//


import Foundation

public protocol AdapterType {
    
    associatedtype Type
    associatedtype ViewType
    
    ///All the elements that are currently exposed from the adapter
    var elements: [Type] { get set }
    
    ///The target view
    var view: ViewType? { get }
    
    init(bufferDiff: BufferDiffType, view: ViewType)
    init(initialElements: [Type], view: ViewType)
}

#if os(iOS)

    public protocol ListItemData { }

    public protocol ListItemType {
        
        /// The reuse identifier for the item passed as argument.
        var reuseIdentifier: String { get }
        
        /// The actual data for this list item.
        var data: ListItemData { get  set }
        
        /// Additional configuration closure for the component.
        var configuration: ((UIView) -> Void)? { get }
    }

#endif

