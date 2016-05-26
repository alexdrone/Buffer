//
//  BufferDiff.swift
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

public protocol BufferDiffType { }

public protocol BufferDiffDelegate: class {
    
    ///Notifies the receiver that the content is about to change
    func bufferDiffWillChangeContent(bufferDiff: BufferDiffType)
    
    ///Notifies the receiver that rows were deleted.
    func bufferDiffDidDeleteElementAtIndices(bufferDiff: BufferDiffType, indices: [UInt])
    
    ///Notifies the receiver that rows were inserted.
    func bufferDiffDidInsertElementsAtIndices(bufferDiff: BufferDiffType, indices: [UInt])

    ///Notifies the receiver that the content updates has ended.
    func bufferDiffDidChangeContent(bufferDiff: BufferDiffType)
    
    ///Notifies the receiver that the content updates has ended.
    ///This callback method is called when the number of changes are too many to be 
    ///handled for the UI thread - it's recommendable to just reload the whole data in this case.
    ///- Note: The 'diffThreshold' property in 'BufferDiff' defines what is the maximum number of changes 
    ///that you want the receiver to be notified for.
    func bufferDiffDidChangeAllContent(bufferDiff: BufferDiffType)
    
    ///Called when one of the observed properties for this object changed
    func bufferDiffDidChangeElementAtIndex(bufferDiff: BufferDiffType, index: UInt)
}

public class BufferDiff<Element: Equatable>: NSObject, BufferDiffType {
    
    typealias ElementType = Element
    
    ///The object that will get notified every time changes occures to the array.
    public weak var delegate: BufferDiffDelegate?
    
    ///The elements in the array observer's buffer.
    public var elements: [Element] {
        return self.frontBuffer
    }
    
    ///Defines what is the maximum number of changes that you want the receiver to be notified for.
    public var diffThreshold = 50
    
    ///If set to 'true' the LCS algorithm is run synchronously on the main thread.
    private var synchronous: Bool = false
    
    ///The two buffers.
    private var frontBuffer = [Element]() {
        willSet {
            assert(NSThread.isMainThread())
            self.observeTrackedKeyPaths(false)
        }
        didSet {
            assert(NSThread.isMainThread())
            self.observeTrackedKeyPaths(true)
        }
    }
    private var backBuffer = [Element]()
    
    ///Sort closure.
    private var sort: ((Element, Element) -> Bool)?
    
    ///Filter closure.
    private var filter: ((Element) -> Bool)?
    
    ///The serial operation queue for this controller.
    private let serialOperationQueue: NSOperationQueue = {
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    private var flags = (isRefreshing: false,
                         shouldRefresh: false)
    
    ///Used if 'Element' is KVO-compliant.
    private var trackedKeyPaths = [String]()
    
    public init(initialArray: [Element],
                sort: ((Element, Element) -> Bool)? = nil,
                filter: ((Element) -> Bool)? = nil) {
        
        self.frontBuffer = initialArray
        self.sort = sort
        self.filter = filter
    }
    
    deinit {
        self.observeTrackedKeyPaths(false)
    }
    
    ///Compute the diffs between the current array and the new one passed as argument.
    public func refresh(newValues: [Element]? = nil, synchronous: Bool = false, completion: ((Void) -> Void)? = nil) {
        
        let new = newValues ?? self.frontBuffer
        
        //should be called on the main thread
        assert(NSThread.isMainThread())
        
        self.backBuffer = new

        //is already refreshing.
        if self.flags.isRefreshing {
            self.flags.shouldRefresh = true
            return
        }
        
        self.flags.isRefreshing = true
        
        self.dispatchOnSerialQueue(synchronous) { 
                
            var backBuffer = self.backBuffer
            
            //filter and sorts (if necessary).
            if let filter = self.filter {
                backBuffer = backBuffer.filter(filter)
            }
            if let sort = self.sort {
               backBuffer = backBuffer.sort(sort)
            }
            
            //compute the diff on the background thread.
            let diff = self.frontBuffer.diff(backBuffer)
            
            self.dispatchOnMainThread(synchronous) {
                
                //swaps the buffers.
                self.frontBuffer = backBuffer
                
                
                if diff.insertions.count < self.diffThreshold && diff.deletions.count < self.diffThreshold {
                    self.delegate?.bufferDiffWillChangeContent(self)
                    self.delegate?.bufferDiffDidInsertElementsAtIndices(self, indices: diff.insertions.map({ UInt($0.idx) }))
                    self.delegate?.bufferDiffDidDeleteElementAtIndices(self, indices: diff.deletions.map({ UInt($0.idx) }))
                    self.delegate?.bufferDiffDidChangeContent(self)
                } else {
                    self.delegate?.bufferDiffDidChangeAllContent(self)
                }
                
                //re-rerun refresh if necessary.
                self.flags.isRefreshing = false
                if self.flags.shouldRefresh {
                    self.flags.shouldRefresh = false
                    self.refresh(self.backBuffer)
                }
                
                completion?()
            }
        }
    }
    
    ///This message is sent to the receiver when the value at the specified key path relative to the given object has changed.
    public override func observeValueForKeyPath(keyPath: String?,
                                                ofObject object: AnyObject?,
                                                         change: [String : AnyObject]?,
                                                         context: UnsafeMutablePointer<Void>) {
        
        if context != &__observationContext {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        if self.trackedKeyPaths.contains(keyPath!) {
            self.objectDidChangeValueForKeyPath(keyPath, object: object)
        }
        
    }
}

//MARK: KVO Extension

extension BufferDiff where Element: AnyObject {
    
    ///Observe the keypaths passed as argument.
    public func trackKeyPaths(keypaths: [String]) {
        self.observeTrackedKeyPaths(false)
        self.trackedKeyPaths = keypaths
        self.observeTrackedKeyPaths()
    }
}

extension BufferDiff {
    
    ///Adds or remove observations.
    ///- Note: This code is executed only when 'Element: AnyObject'.
    private func observeTrackedKeyPaths(observe: Bool = true) {
        if self.trackedKeyPaths.count == 0 {
            return
        }
        for keyPath in trackedKeyPaths {
            for item in self.frontBuffer {
                if let object = item as? AnyObject {
                    if observe {
                        object.addObserver(self,
                                           forKeyPath: keyPath,
                                           options: NSKeyValueObservingOptions.New,
                                           context: &__observationContext)
                        
                    } else {
                        object.removeObserver(self, forKeyPath: keyPath)
                    }
                }
            }
        }
    }
    
    ///- Note: This code is executed only when 'Element: AnyObject'.
    private func objectDidChangeValueForKeyPath(keyPath: String?, object: AnyObject?) {
        dispatchOnMainThread {
            self.refresh() {
                var idx = 0
                for obj in self.frontBuffer {
                    if (object as? Element) == obj { break }
                    idx += 1
                }
                if idx < self.frontBuffer.count {
                    self.delegate?.bufferDiffDidChangeElementAtIndex(self, index: UInt(idx))
                }
            }
        }
    }
}

private var __observationContext: UInt8 = 0

//MARK: Dispatch Helpers

extension BufferDiff {
    
    private func dispatchOnMainThread(synchronous: Bool = false, block: (Void) -> (Void)) {
        if synchronous {
            assert(NSThread.isMainThread())
            block()
        } else {
            if NSThread.isMainThread() { block()
            } else { dispatch_async(dispatch_get_main_queue(), block) }
        }
    }
    
    private func dispatchOnSerialQueue(synchronous: Bool = false, block: (Void) -> (Void)) {
        if synchronous {
            block()
        } else {
            self.serialOperationQueue.addOperationWithBlock(){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block)
            }
        }
    }
}



