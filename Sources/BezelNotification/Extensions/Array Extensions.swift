//
//  Array Extensions.swift
//  BH Bezel Notification
//
//  Created by Ben Leggiero on 2017-11-10.
//  Copyright © 2017 Ben Leggiero. All rights reserved.
//

import Foundation



internal extension Array where Element : AnyObject {
    
    /// Removes the given element from this array
    ///
    /// - Parameter element: The object to remove
    /// - Returns: The removed object, if it was in the array
    @discardableResult
    mutating func remove(_ element: Element) -> Element? {
        if let foundIndex = self.index(of: element) {
            return remove(at: foundIndex)
        }
        else {
            return nil
        }
    }
    
    
    /// Finds the index of the first instance of the given object in this array, or `nil` if it isn't in it
    ///
    /// - Parameter element: The object whose index to find
    /// - Returns: The index of the first instance of `element`, or `nil` if it's not in this array
    func index(of element: Element) -> Int? {
        return firstIndex(where: { $0 === element })
    }
}
