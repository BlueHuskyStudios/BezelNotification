//
//  NSSize Extensions.swift
//  BH Bezel Notification
//
//  Created by Ben Leggiero on 2017-11-10.
//  Copyright © 2017 Ben Leggiero. All rights reserved.
//

import Foundation



extension NSSize {
    
    init(copyOf original: NSSize) {
        self.init(width: original.width, height: original.height)
    }
    
    
    init(scaling original: NSSize, toFitWithin parent: NSSize, approach: NSImageScaling) {
        
        switch approach {
        case .scaleAxesIndependently:
            self.init(copyOf: parent)
            
        case .scaleNone:
            self.init(copyOf: original)
            
        case .scaleProportionallyDown:
            // If it already fits, no need to scale. Just use the original.
            if original.height < parent.height
                && original.width < parent.width {
                self.init(copyOf: original)
            }
            else {
                fallthrough
            }
            
        case .scaleProportionallyUpOrDown:
            let tooManyPixelsTall = max(0, original.height - parent.height)
            let tooManyPixelsWide = max(0, original.width - parent.width)
            
            let shouldScaleToFitHeight = tooManyPixelsTall > tooManyPixelsWide
            
            if shouldScaleToFitHeight {
                self.init(scaling: original, proportionallyToFitHeight: parent.height)
            }
            else {
                self.init(scaling: original, proportionallyToFitWidth: parent.width)
            }
        }
    }
    
    
    init(scaling original: NSSize, proportionallyToFitHeight newHeight: CGFloat) {
        let percentChange = newHeight / original.height
        self.init(width: original.width * percentChange,
                  height: newHeight)
    }
    
    
    init(scaling original: NSSize, proportionallyToFitWidth newWidth: CGFloat) {
        let percentChange = newWidth / original.width
        self.init(width: newWidth,
                  height: original.height * percentChange)
    }
    
    
    var aspectRatio: CGFloat {
        return width / height
    }
}



public extension NSSize {
    public static func *(lhs: Double, rhs: NSSize) -> NSSize {
        return CGFloat(lhs) * rhs
    }
    
    
    public static func *(lhs: NSSize, rhs: Double) -> NSSize {
        return lhs * CGFloat(rhs)
    }
    
    
    public static func *(lhs: CGFloat, rhs: NSSize) -> NSSize {
        return NSSize(width: lhs * rhs.width,
                      height: lhs * rhs.height)
    }
    
    
    public static func *(lhs: NSSize, rhs: CGFloat) -> NSSize {
        return NSSize(width: lhs.width * rhs,
                      height: lhs.height * rhs)
    }
    
    
    public static func *(lhs: NSSize, rhs: NSSize) -> NSSize {
        return NSSize(width: lhs.width * rhs.width,
                      height: lhs.height * rhs.height)
    }
}
