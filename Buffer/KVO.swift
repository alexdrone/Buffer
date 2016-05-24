//
//  KVO.swift
//  BufferDiff
//
//  Created by Alex Usbergo on 02/05/16.
//
//  Copyright (c) 2016 Alex Usbergo.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

// MARK: KVO Change set

///Represent a change for a KVO compliant property
public struct KVOChange<O:AnyObject, T> {
    
    ///The associated object for this change
    public let object: O?
    
    ///The keyPath the triggered this change
    public let keyPath: String
    
    ///The new value (if applicable)
    public let new: T?
    
    ///The old value (if applicable)
    public let old: T?
}

enum KVObserverError: ErrorType {
    
    ///This error is thrown when the object passed as argument for the observation
    ///doesn't respond to the keyPath selector.
    case UnrecognizedKeyPathForObject(error: String)
}

// MARK: Observer class

///A simple, efficient and thread-safe abstraction around Key-Value Observation
///An instance of this class can register itself as an observer for several different objects (and for different keyPaths)
///The observation deregistration is not required since it automatically perfomed when this instance is deallocated.
public class KVObserver {
    
    ///Initial|New|Old
    public static let defaultOptions: UInt = 0x01|0x02|0x04
    
    private var lock = OS_SPINLOCK_INIT
    private let infos = NSMapTable(keyOptions: NSPointerFunctionsOptions.StrongMemory.union(NSPointerFunctionsOptions.ObjectPointerPersonality),
                                   valueOptions: NSPointerFunctionsOptions.StrongMemory.union(NSPointerFunctionsOptions.ObjectPersonality), capacity: 0)
    
    public init() {
        
    }
    
    deinit {
        self.unobserveAll()
    } 
    //MARK: Public methods
    
    ///Register this object for observation of the given keyPath for the given object.
    public func onChange<O: AnyObject, T>(keyPath: String, object: O, options: NSKeyValueObservingOptions = NSKeyValueObservingOptions(rawValue: defaultOptions), change: (KVOChange<O, T>) -> Void) throws {
        try self.onChange(keyPath, object: object, options: options, shouldDispatchChangeOnMainThread: false, change: change)
    }
    
    public func onChange<O: AnyObject, T>(keyPath: String, object: O, options: NSKeyValueObservingOptions, shouldDispatchChangeOnMainThread: Bool, change: (KVOChange<O, T>) -> Void) throws {
        
        guard (object as! NSObject).respondsToSelector(Selector(keyPath)) else {
            throw KVObserverError.UnrecognizedKeyPathForObject(error: " \(object) doesn't respond to selector \(keyPath)")
        }
        
        let info = KVObservationInfo<O, T>(keyPath: keyPath, options: options, shouldDispatchChangeOnMainThread: false, change: change)
        var shouldObserve = true
        
        withUnsafeMutablePointer(&lock, OSSpinLockLock)
        
        //tries to retrieve the set
        var setForObject = self.infos.objectForKey(object)
        
        //it allocates a new set if necessary
        if setForObject == nil {
            setForObject = NSMutableSet()
            self.infos.setObject(setForObject, forKey: object)
        }
        
        //if there's already an observation registered skips it, otherwise it adds the observation info to the set
        if setForObject?.member(info) != nil {
            shouldObserve = false
        } else {
            setForObject?.addObject(info)
        }
        
        withUnsafeMutablePointer(&lock, OSSpinLockUnlock)
        
        //finally adds the observation info to the sharedMananger
        if shouldObserve {
            KVObserverManager.sharedManager.observe(object, info: info)
        }
    }
    
    ///Stops all the observation
    public func unobserveAll() {
        
        withUnsafeMutablePointer(&lock, OSSpinLockLock)
        
        //creates a copy of the map and removes all the observation infos from it
        let copy = self.infos.copy() as! NSMapTable
        self.infos.removeAllObjects()
        withUnsafeMutablePointer(&lock, OSSpinLockUnlock)
        
        //now remove the observations

        let enumerator = copy.keyEnumerator()
        while let object: AnyObject = enumerator.nextObject() {
            
            guard let set = copy.objectForKey(object) as? NSSet else { continue }
            for obj in set {
                
                //removes the kvo info from the shared manager
                guard let info = obj as? KVOChangeFactoring else { continue }
                KVObserverManager.sharedManager.unobserve(object, info: info)
            }
        }
        
    }
    
}

// MARK: Private

private protocol KVOChangeFactoring {
    
    //uniquing
    var uniqueIdenfier: Int { get }
    var keyPath: String { get }
    
    //Creates and execute an observer change block with an associated KVOChange object
    func kvoChange(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?)
}

private class KVObservationInfo<O:AnyObject, T>: NSObject, KVOChangeFactoring {
    
    private let keyPath: String
    private let options: NSKeyValueObservingOptions
    private let change: (KVOChange<O, T>) -> Void
    private let shouldDispatchChangeOnMainThread: Bool
    
    //uniquing
    private var uniqueIdenfier = NSUUID().UUIDString.hash
    
    init(keyPath: String, options: NSKeyValueObservingOptions, shouldDispatchChangeOnMainThread: Bool, change: (KVOChange<O, T>) -> Void) {
        self.keyPath = keyPath
        self.options = options
        self.change = change
        self.shouldDispatchChangeOnMainThread = shouldDispatchChangeOnMainThread
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        
       let result = super.isEqual(object)
        
        if !result {
            return self.keyPath == object?.keyPath
        }

        return result
    }
    
    func kvoChange(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?) {
        
        let new = change?[NSKeyValueChangeNewKey] as? T
        let old = change?[NSKeyValueChangeOldKey] as? T
        let change = KVOChange<O, T>(object: object as? O, keyPath: keyPath!, new: new, old: old)
        
        //runs the callback
        
        //we're not on the mainthread and we're supposed to dispatch the change on the main thread
        if !NSThread.isMainThread() && self.shouldDispatchChangeOnMainThread {
            dispatch_sync(dispatch_get_main_queue(), {[weak self]  () -> Void in
                self?.change(change)
            })
        
        //or simply dispatch the change
        } else {
            self.change(change)
        }
                
    }
    
}

private class KVObserverManager: NSObject {
    
    //singletone
    static let sharedManager = KVObserverManager()
    
    //weak map to the observers
    private var lock = OS_SPINLOCK_INIT
    private var observers = [Int: KVOChangeFactoring]()
    
    func observe<O: AnyObject, T>(object: AnyObject, info: KVObservationInfo<O, T>) {
        
        withUnsafeMutablePointer(&lock, OSSpinLockLock)
        self.observers[info.uniqueIdenfier] = info
        withUnsafeMutablePointer(&lock, OSSpinLockUnlock)
        
        let context = unsafeBitCast(info.uniqueIdenfier, UnsafeMutablePointer<Void>.self)
        (object as! NSObject).addObserver(self, forKeyPath: info.keyPath, options: info.options, context: context)
    }
    
    func unobserve(object: AnyObject, info: KVOChangeFactoring) {
        
        withUnsafeMutablePointer(&lock, OSSpinLockLock)
        self.observers.removeValueForKey(info.uniqueIdenfier)
        withUnsafeMutablePointer(&lock, OSSpinLockUnlock)
        
        let context = unsafeBitCast(info.uniqueIdenfier, UnsafeMutablePointer<Void>.self)
        (object as! NSObject).removeObserver(self, forKeyPath: info.keyPath, context: context)
    }
    
    ///This message is sent to the receiver when the value at the specified key path relative to the given object has changed.
    //The key path, relative to object, to the value that has changed.
    override private func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if object == nil || context == nil {
            return
        }
        
        withUnsafeMutablePointer(&lock, OSSpinLockLock)
        let info = self.observers[unsafeBitCast(context, Int.self)]
        withUnsafeMutablePointer(&lock, OSSpinLockUnlock)
        
        info?.kvoChange(keyPath, ofObject: object, change: change)
    }
}
