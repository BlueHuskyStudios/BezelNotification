//
//  NSFont Extensions.swift
//  BH Bezel Notification
//
//  Created by Ben Leggiero on 2017-11-10.
//  Copyright © 2017 Ben Leggiero. All rights reserved.
//

import AppKit



public extension NSFont {
    public static var systemFont: NSFont {
        return systemFont(ofSize: systemFontSize)
    }
    
    
    public static func systemFont(forControlSize controlSize: NSControl.ControlSize) -> NSFont {
        return systemFont(ofSize: systemFontSize(for: controlSize))
    }
}
