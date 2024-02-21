//
//  Cross-kit Image + Initializers.swift
//  BlueToast Demo App
//
//  Created by The Northstar✨ System on 2024-02-14.
//  Copyright © 2024 Ky Leggiero. All rights reserved.
//

import Foundation
import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

import CrossKitTypes



public extension Image {
    init(nativeImage: NativeImage) {
        #if canImport(AppKit)
        self.init(nsImage: nativeImage)
        #elseif canImport(UIKit)
        self.init(uiImage: nativeImage)
        #endif
    }
}



public extension Image {
    
    func nativeImage() -> NativeImage? {
        let view = NoInsetHostingView(rootView: self)
        view.setFrameSize(view.fittingSize)
        return view.bitmapImage()
    }
}



// MARK: - Private utilities

private class NoInsetHostingView<V: View>: NSHostingView<V> {
    @inline(__always)
    override var safeAreaInsets: NSEdgeInsets { .init() }
}



private extension NSView {
    
    func bitmapImage() -> NSImage? {
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        cacheDisplay(in: bounds, to: rep)
        guard let cgImage = rep.cgImage else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: bounds.size)
    }
}
