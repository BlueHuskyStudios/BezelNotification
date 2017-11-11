//
//  Array Extensions.swift
//  BH Bezel
//
//  Created by Ben Leggiero on 2017-11-10.
//  Copyright © 2017 Ben Leggiero. All rights reserved.
//

import Foundation



public extension Array where Element : AnyObject {
    
    @discardableResult
    public mutating func remove(_ element: Element) -> Element? {
        if let foundIndex = self.index(of: element) {
            return remove(at: foundIndex)
        }
        else {
            return nil
        }
    }
    
    
    public func index(of element: Element) -> Int? {
        return index(where: { $0 === element })
    }
}
