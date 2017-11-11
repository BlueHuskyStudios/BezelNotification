//
//  CGContext Extensions.swift
//  BH Bezel
//
//  Created by Ben Leggiero on 2017-11-10.
//  Copyright © 2017 Ben Leggiero. All rights reserved.
//

import Foundation



extension CGContext {
    func draw(text string: String, at point: CGPoint, color: NSColor, font: NSFont = .systemFont(ofSize: NSFont.systemFontSize)) {
        (string as NSString).draw(at: point,
                                  withAttributes: [
                                    .foregroundColor : color,
                                    .font : font
            ])
    }
}
