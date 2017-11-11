//
//  NSWindow+Fade.swift
//  BH Bezel
//
//  Created by Ben Leggiero on 2017-11-09.
//  Copyright © 2017 Ben Leggiero. All rights reserved.
//

import Foundation



private let defaultWindowAnimationDuration: TimeInterval = 0.25



extension NSWindow {
    
    typealias AnimationCompletionHandler = () -> Void
    
    
    
    enum DisplaySelector {
        case makeKey
        case makeKeyAndOrderFront
        case orderFront
        case orderFrontRegardless
        
        
        func run(on window: NSWindow, sender: Any?) {
            switch self {
            case .makeKey: window.makeKey()
            case .makeKeyAndOrderFront: window.makeKeyAndOrderFront(sender)
            case .orderFront: window.orderFront(sender)
            case .orderFrontRegardless: window.orderFrontRegardless()
            }
        }
    }
    
    
    
    enum CloseSelector {
        case orderOut
        case close
        case performClose
        
        
        func run(on window: NSWindow, sender: Any?) {
            switch self {
            case .orderOut: window.orderOut(sender)
            case .close: window.close()
            case .performClose: window.performClose(sender)
            }
        }
    }
    
    
    
    @IBAction func fadeIn(_ sender: Any?) {
        self.fadeIn(sender: sender, duration: defaultWindowAnimationDuration)
    }
    
    
    func fadeIn(sender: Any?,
                duration: TimeInterval,
                timingFunction: CAMediaTimingFunction? = .init(name: kCAMediaTimingFunctionEaseInEaseOut),
                startingAlpha: CGFloat = 0,
                targetAlpha: CGFloat = 1,
                displaySelector: DisplaySelector = .makeKeyAndOrderFront,
                completionHandler: AnimationCompletionHandler? = nil) {
        
        alphaValue = startingAlpha
        
        displaySelector.run(on: self, sender: sender)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = timingFunction
            animator().alphaValue = targetAlpha
        }, completionHandler: completionHandler)
    }
    
    
    @IBAction func fadeOut(_ sender: Any?) {
        self.fadeOut(sender: sender, duration: defaultWindowAnimationDuration)
    }
    
    
    func fadeOut(sender: Any?,
                 duration: TimeInterval,
                 timingFunction: CAMediaTimingFunction? = .init(name: kCAMediaTimingFunctionEaseInEaseOut),
                 targetAlpha: CGFloat = 0,
                 resetAlphaAfterAnimation: Bool = true,
                 closeSelector: CloseSelector = .orderOut,
                 completionHandler: AnimationCompletionHandler? = nil) {
        
        let startingAlpha = self.alphaValue
        
        NSAnimationContext.runAnimationGroup({ context in
            
            context.duration = duration
            context.timingFunction = timingFunction
            animator().alphaValue = targetAlpha
            
        }, completionHandler: { [weak weakSelf = self] in
            guard let weakSelf = weakSelf else { return }
            
            closeSelector.run(on: weakSelf, sender: sender)
            
            if resetAlphaAfterAnimation {
                weakSelf.alphaValue = startingAlpha
            }
            
            completionHandler?()
        })
    }
}
