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

public protocol ListContainerView: class { }
public protocol ListViewCell: class { }

#if os(iOS)
    extension UITableView: ListContainerView { }
    extension UICollectionView: ListContainerView { }
    extension UITableViewCell: ListViewCell { }
    extension UICollectionViewCell: ListViewCell { }
#endif

public func ==<Type>(lhs: AnyListItem<Type>, rhs: AnyListItem<Type>) -> Bool {
    return lhs.reuseIdentifier == rhs.reuseIdentifier && lhs.state == rhs.state
}

public struct AnyListItem<Type: Equatable>: Equatable {
    
    ///The reuse identifier for the cell passed as argument.
    public var reuseIdentifier: String
    
    ///The actual item data.
    public var state: Type
    
    ///The TableView, or the CollectionView that will own this element.
    public let referenceView: ListContainerView?
    
    public var cellConfiguration: ((ListViewCell, Type) -> Void)?
    
    #if os(iOS)
        public init<V: PrototypeViewCell>(type: V.Type,
                                         referenceView: ListContainerView,
                                         reuseIdentifer: String = String(V.self),
                                         state: Type,
                                         configurationClosure: ((ListViewCell, Type) -> Void)? = nil) {
            
            //registers the prototype cell if necessary.
            if !Prototypes.isPrototypeCellRegistered(reuseIdentifer) {
                let cell = V(reuseIdentifier: reuseIdentifer)
                Prototypes.registerPrototypeCell(reuseIdentifer, cell: cell)
            }
            
            self.reuseIdentifier = reuseIdentifer
            self.cellConfiguration = configurationClosure
            self.referenceView = referenceView
            self.state = state
            self.configureRefenceView(type)
        }
    #endif
    
    public init<V: ListViewCell>(type: V.Type,
                                 referenceView: ListContainerView? = nil,
                                 reuseIdentifer: String = String(V.self),
                                 state: Type,
                                 configurationClosure: ((ListViewCell, Type) -> Void)? = nil) {

        self.reuseIdentifier = reuseIdentifer
        self.cellConfiguration = configurationClosure
        self.referenceView = referenceView
        self.state = state
        self.configureRefenceView(type)
    }
    
    private func configureRefenceView(cellClass: AnyClass) {
        #if os(iOS)
            if let tableView = self.referenceView as? UITableView {
                tableView.registerClass(cellClass, forCellReuseIdentifier: self.reuseIdentifier)
            }
            if let collectionView = self.referenceView as? UICollectionView {
                collectionView.registerClass(cellClass, forCellWithReuseIdentifier: self.reuseIdentifier)
            }
        #endif
    }
}


