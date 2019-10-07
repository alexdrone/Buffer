// forked from:
// https://github.com/muukii/ListDiff/blob/master/Sources/ListDiff.swift
// https://github.com/Instagram/IGListKit/blob/master/Source/Common/IGListDiff.mm
// https://github.com/muukii/DataSources/blob/master/Sources/Diff/Diff.swift

public typealias EqualityChecker<T: Diffable> = (T, T) -> Bool

/// An object that can be diffed.
public protocol Diffable {
  /// The identifier used from the diffing algorithm.
  var diffIdentifier: String { get }
}

public protocol Diffing {
  /// Return the diff result from 'oldArray' to 'newArray'
  static func diffing<T: Diffable>(
    oldArray: [T],
    newArray: [T],
    isEqual: EqualityChecker<T>
  ) -> DiffResultType
}

public protocol DiffResultType {
  /// The computed required insert to match the destination array.
  var inserts: IndexSet { get set }

  /// The computed required updates to match the destination array.
  var updates: IndexSet { get set }

  /// The computed required deletes to match the destination array.
  var deletes: IndexSet { get set }

  /// The computed required moves to match the destination array.
  var moves: [MoveIndex] { get set }
}

public struct MoveIndex: Equatable {
  /// The source index.
  public let from: Int

  /// The target index.
  public let to: Int

  public init(from: Int, to: Int) {
    self.from = from
    self.to = to
  }

  /// Returns *true* only if the two indices are the same.
  public static func == (lhs: MoveIndex, rhs: MoveIndex) -> Bool {
    return lhs.from == rhs.from && lhs.to == rhs.to
  }
}

public struct DiffResult<H: Hashable>: DiffResultType {
  /// The computed required insert to match the destination array.
  public var inserts = IndexSet()

  /// The computed required updates to match the destination array.
  public var updates = IndexSet()

  /// The computed required deletes to match the destination array.
  public var deletes = IndexSet()

  /// The computed required moves to match the destination array.
  public var moves = [MoveIndex]()

  /// Internal data.
  public var oldMap = [H: Int]()

  public var newMap = [H: Int]()

  public func validate<T: Diffable>(_ oldArray: [T], _ newArray: [T]) -> Bool {
    return (oldArray.count + self.inserts.count - self.deletes.count) == newArray.count
  }

  public func oldIndexFor(identifier: H) -> Int? {
    return self.oldMap[identifier]
  }

  public func newIndexFor(identifier: H) -> Int? {
    return self.newMap[identifier]
  }
}

extension DiffResultType {
  /// Returns *true* if there are any changes associated to this diff.
  public var hasChanges: Bool {
    return inserts.isEmpty && deletes.isEmpty && updates.isEmpty && moves.isEmpty
  }

  /// The number of changes.
  public var changeCount: Int {
    return inserts.count + deletes.count + updates.count + moves.count
  }
}

/// https://github.com/Instagram/IGListKit/blob/master/Source/IGListDiff.mm
public enum Diff: Diffing {
  /// Internal stack data structure.
  private struct Stack<T> {
    /// All of the items in the stack.
    var items = [T]()

    /// Whether there are any elements in this stack.
    var isEmpty: Bool { return self.items.isEmpty }

    /// Adds a new elements to the stack.
    mutating func push(_ item: T) {
      items.append(item)
    }

    /// Remove the most recently added element to the stack.
    mutating func pop() -> T {
      return items.removeLast()
    }
  }

  /// Used to track data stats while diffing.
  /// We expect to keep a reference of entry, thus its declaration as (final) class.
  private final class Entry {
    /// The number of times the data occurs in the old array
    var oldCounter: Int = 0

    /// The number of times the data occurs in the new array
    var newCounter: Int = 0

    /// The indexes of the data in the old array
    var oldIndexes: Stack<Int?> = Stack<Int?>()

    /// Flag marking if the data has been updated between arrays by equality check
    var updated: Bool = false

    /// Returns `true` if the data occur on both sides, `false` otherwise
    var occurOnBothSides: Bool {
      return self.newCounter > 0 && self.oldCounter > 0
    }

    func push(new index: Int?) {
      self.newCounter += 1
      self.oldIndexes.push(index)
    }

    func push(old index: Int?) {
      self.oldCounter += 1
      self.oldIndexes.push(index)
    }
  }

  /// Track both the entry and the algorithm index. Default the index to `nil`
  private struct Record {
    let entry: Entry
    var index: Int?

    init(_ entry: Entry) {
      self.entry = entry
      self.index = nil
    }
  }

  private struct OptimizedIdentity<E: Hashable>: Hashable {
    let hashValue: Int
    let identity: UnsafePointer<E>

    init(_ identity: UnsafePointer<E>) {
      self.identity = identity
      self.hashValue = identity.pointee.hashValue
    }

    static func == <E>(lhs: OptimizedIdentity<E>, rhs: OptimizedIdentity<E>) -> Bool {
      if lhs.hashValue != rhs.hashValue { return false }
      if lhs.identity.distance(to: rhs.identity) == 0 { return true }
      return lhs.identity.pointee == rhs.identity.pointee
    }
  }

  /// The diffing algorithm.
  public static func diffing<T: Diffable>(
    oldArray: [T],
    newArray: [T],
    isEqual: EqualityChecker<T>
  ) -> DiffResultType {
    // symbol table uses the old/new array `diffIdentifier` as the key and `Entry` as the value
    var table = [OptimizedIdentity: Entry].init(minimumCapacity: oldArray.count)
    let __oldArray = ContiguousArray(oldArray)
    let __newArray = ContiguousArray(newArray)
    // pass 1
    // create an entry for every item in the new array
    // increment its new count for each occurence
    // record `nil` for each occurence of the item in the new array
    var newRecords = __newArray.map { (newRecord) -> Record in
      var identifier = newRecord.diffIdentifier
      let key = OptimizedIdentity(&identifier)
      if let entry = table[key] {
        // add `nil` for each occurence of the item in the new array
        entry.push(new: nil)
        return Record(entry)
      } else {
        let entry = Entry()
        // add `nil` for each occurence of the item in the new array
        entry.push(new: nil)
        table[key] = entry
        return Record(entry)
      }
    }
    // pass 2
    // update or create an entry for every item in the old array
    // increment its old count for each occurence
    // record the old index for each occurence of the item in the old array
    // MUST be done in descending order to respect the oldIndexes stack construction
    var oldRecords = __oldArray.enumerated().reversed().map { (i, oldRecord) -> Record in
      var identifier = oldRecord.diffIdentifier
      let key = OptimizedIdentity(&identifier)
      if let entry = table[key] {
        // push the old indices where the item occured onto the index stack
        entry.push(old: i)
        return Record(entry)
      } else {
        let entry = Entry()
        // push the old indices where the item occured onto the index stack
        entry.push(old: i)
        table[key] = entry
        return Record(entry)
      }
    }
    // pass 3
    // handle data that occurs in both arrays
    newRecords.enumerated().filter { $1.entry.occurOnBothSides }.forEach { (i, newRecord) in
      let entry = newRecord.entry
      // grab and pop the top old index. if the item was inserted this will be nil
      assert(!entry.oldIndexes.isEmpty, "Old indexes is empty while iterating new item \(i).")
      guard let oldIndex = entry.oldIndexes.pop() else {
        return
      }
      if oldIndex < __oldArray.count {
        let n = __newArray[i]
        let o = __oldArray[oldIndex]
        if isEqual(n, o) == false {
          entry.updated = true
        }
      }
      // if an item occurs in the new and old array, it is unique
      // assign the index of new and old records to the opposite index (reverse lookup)
      newRecords[i].index = oldIndex
      oldRecords[oldIndex].index = i
    }
    // storage for final indexes
    var result = DiffResult<String>()
    // track offsets from deleted items to calculate where items have moved
    // iterate old array records checking for deletes
    // increment offset for each delete
    var runningOffset = 0
    let deleteOffsets = oldRecords.enumerated().map { (i, oldRecord) -> Int in
      let deleteOffset = runningOffset
      // if the record index in the new array doesn't exist, its a delete
      if oldRecord.index == nil {
        result.deletes.insert(i)
        runningOffset += 1
      }
      result.oldMap[__oldArray[i].diffIdentifier] = i
      return deleteOffset
    }
    //reset and track offsets from inserted items to calculate where items have moved
    runningOffset = 0
    _
      = newRecords.enumerated().map { (i, newRecord) -> Int in
        let insertOffset = runningOffset
        if let oldIndex = newRecord.index {
          // note that an entry can be updated /and/ moved
          if newRecord.entry.updated {
            result.updates.insert(oldIndex)
          }
          // calculate the offset and determine if there was a move
          // if the indexes match, ignore the index
          let deleteOffset = deleteOffsets[oldIndex]
          if (oldIndex - deleteOffset + insertOffset) != i {
            result.moves.append(MoveIndex(from: oldIndex, to: i))
          }
        } else {  // add to inserts if the opposing index is nil
          result.inserts.insert(i)
          runningOffset += 1
        }
        result.newMap[__newArray[i].diffIdentifier] = i
        return insertOffset
      }
    assert(result.validate(oldArray, newArray))
    return result
  }
}

// MARK: - Diffable extensions.

extension Int: Diffable {
  public var diffIdentifier: String { return "\(self)" }
}
extension NSNumber: Diffable {
  public var diffIdentifier: String { return "\(self)" }
}
extension String: Diffable {
  public var diffIdentifier: String { return self }
}
extension NSString: Diffable {
  public var diffIdentifier: String { return "\(self)" }
}
extension FloatingPoint {
  public var diffIdentifier: String { return "\(self)" }
}
extension Float: Diffable {}
extension Double: Diffable {}
