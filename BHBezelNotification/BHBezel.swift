//
//  BHBezel.swift
//  BH Bezel
//
//  Created by Ben Leggiero on 2017-11-09.
//  Copyright © 2017 Ben Leggiero. All rights reserved.
//

import Cocoa



private let bezelStyleMask: NSWindow.StyleMask = [.borderless]

private var bezelWindows = Set<BHBezelWindow>()



public struct BHBezel {
    
    public typealias AfterHideCallback = () -> Void
    
    /// Shows a BHBezel notification using the given parameters.
    /// See `BHBezelParameters` for documentation of each parameter.
    ///
    /// If you want to manually dismiss th enotification, rather than trusting the time to live, you can give a very
    /// large nubmer for `timeToLive` and call the resulting delegate's `donePresentingBezel()` function.
    ///
    /// - Returns: A delegate that allows control of the bezel after it's shown
    /// - SeeAlso: BHBezelParameters
    @discardableResult
    public static func show(messageText: String,
                            icon: NSImage? = nil,
                            
                            location: BezelLocation = BezelParameters.defaultLocation,
                            size: BezelSize = BezelParameters.defaultSize,
                            
                            timeToLive: BezelTimeToLive = BezelParameters.defaultTimeToLive,
                            fadeInAnimationDuration: TimeInterval = BezelParameters.defaultFadeInAnimationDuration,
                            fadeOutAnimationDuration: TimeInterval = BezelParameters.defaultFadeOutAnimationDuration,
                            
                            cornerRadius: CGFloat = BezelParameters.defaultCornerRadius,
                            tint: NSColor = BezelParameters.defaultBackgroundTint,
                            messageLabelFont: NSFont = BezelParameters.defaultMessageLabelFont,
                            messageLabelColor: NSColor = BezelParameters.defaultMessageLabelColor,
                            
                            afterHideCallback: @escaping AfterHideCallback = {}
        ) -> BezelDelegate {
        
        return self.show(
            with: BezelParameters(
                messageText: messageText,
                icon: icon,
                
                location: location,
                size: size,
                
                timeToLive: timeToLive,
                fadeInAnimationDuration: fadeInAnimationDuration,
                fadeOutAnimationDuration: fadeOutAnimationDuration,
                
                //messageLabelBaselineOffsetFromBottomOfBezel: default,
                cornerRadius: cornerRadius,
                backgroundTint: tint,
                messageLabelFont: messageLabelFont,
                messageLabelColor: messageLabelColor
            ),
            
            afterHideCallback: afterHideCallback)
    }
    
    
    /// Shows a BHBezel notification using the given parameters.
    /// See `BHBezelParameters` for documentation of each parameter.
    ///
    /// If you want to manually dismiss th enotification, rather than trusting the time to live, you can give a very
    /// large nubmer for `timeToLive` and call the resulting delegate's `donePresentingBezel()` function.
    ///
    /// - Returns: A delegate that allows control of the bezel after it's shown
    /// - SeeAlso: BHBezelParameters
    public static func show(with parameters: BezelParameters,
                            afterHideCallback: @escaping AfterHideCallback = {}
        ) -> BezelDelegate {
        
        let bezelWindow = BHBezelWindow(parameters: parameters)
        bezelWindows.insert(bezelWindow)
        
        
        
        class BHBezelDelegateImpl: BezelDelegate {

            var shouldFadeOut = true
            weak var bezelWindow: BHBezelWindow?
            let afterHideCallback: AfterHideCallback
            
            init(bezelWindow: BHBezelWindow,
                 afterHideCallback: @escaping AfterHideCallback) {
                self.bezelWindow = bezelWindow
                self.afterHideCallback = afterHideCallback
            }
            
            func donePresentingBezel() {
                guard
                    shouldFadeOut,
                    let bezelWindow = bezelWindow
                    else {
                        return
                }
                shouldFadeOut = false

                bezelWindow.fadeOut(sender: nil,
                                    duration: bezelWindow.parameters.fadeOutAnimationDuration,
                                    closeSelector: .close)
                { [weak weakSelf = self] in
                    bezelWindows.remove(bezelWindow)
                    weakSelf?.afterHideCallback()
                }
            }
        }
        
        
        
        let delegate = BHBezelDelegateImpl(bezelWindow: bezelWindow, afterHideCallback: afterHideCallback)
        
        bezelWindow.fadeIn(sender: nil,
                           duration: parameters.fadeInAnimationDuration,
                           displaySelector: .orderFrontRegardless)
        
        Timer.scheduledTimer(withTimeInterval: parameters.timeToLive.inSeconds, repeats: false) { _ in
            delegate.donePresentingBezel()
        }
        
        return delegate
    }
}



public protocol BezelDelegate : AnyObject {
    /// Called when the bezel is done and should be faded out, closed, and destroyed.
    /// This is useful for hiding it early or manually.
    func donePresentingBezel()
}



public struct BezelParameters {
    
    public static let defaultLocation: BezelLocation = .normal
    public static let defaultSize: BezelSize = .normal
    public static let defaultTimeToLive: BezelTimeToLive = .short
    
    public static let defaultFadeInAnimationDuration: TimeInterval = 0
    public static let defaultFadeOutAnimationDuration: TimeInterval = 0.25
    
    public static let defaultCornerRadius: CGFloat = 18
    public static let defaultBackgroundTint = NSColor(calibratedWhite: 0, alpha: 1)
    public static let defaultMessageLabelBaselineOffsetFromBottomOfBezel: CGFloat = 20
    public static let defaultMessageLabelFontSize: CGFloat = 18
    public static let defaultMessageLabelFont = NSFont.systemFont(ofSize: defaultMessageLabelFontSize)
    public static let defaultMessageLabelColor = NSColor.labelColor
    
    
    // MARK: Basics
    
    /// The text to show in the bezel notification's message area
    let messageText: String
    
    /// The icon to show in the bezel notification's icon area
    let icon: NSImage?
    
    
    // MARK: Presentation
    
    /// The location on the screen at which to display the bezel notification
    let location: BezelLocation
    
    /// The size of the bezel notification
    let size: BezelSize
    
    /// The number of seconds to display the bezel notification on the screen
    let timeToLive: BezelTimeToLive
    
    
    // MARK: Animations
    
    /// The number of seconds that it takes to fade in the bezel notification
    let fadeInAnimationDuration: TimeInterval
    
    /// The number of seconds that it takes to fade out the bezel notification
    let fadeOutAnimationDuration: TimeInterval
    
    
    // MARK: Drawing
    
    /// The radius of the bezel notification's corners, in points
    let cornerRadius: CGFloat
    
    /// The tint of the bezel notification's background
    let backgroundTint: NSColor
    
    /// The distance from the bottom of the bezel notification's bottom at which the baseline of the message label sits
    let messageLabelBaselineOffsetFromBottomOfBezel: CGFloat
    
    /// The font used for the message label
    let messageLabelFont: NSFont
    
    /// The text color of the message label
    let messageLabelColor: NSColor
    
    
    public init(messageText: String,
         icon: NSImage? = nil,
         
         location: BezelLocation = defaultLocation,
         size: BezelSize = defaultSize,
         timeToLive: BezelTimeToLive = defaultTimeToLive,
         
         fadeInAnimationDuration: TimeInterval = defaultFadeInAnimationDuration,
         fadeOutAnimationDuration: TimeInterval = defaultFadeOutAnimationDuration,
         
         cornerRadius: CGFloat = defaultCornerRadius,
         backgroundTint: NSColor = defaultBackgroundTint,
         messageLabelBaselineOffsetFromBottomOfBezel: CGFloat = defaultMessageLabelBaselineOffsetFromBottomOfBezel,
         messageLabelFont: NSFont = defaultMessageLabelFont,
         messageLabelColor: NSColor = defaultMessageLabelColor
        ) {
        self.messageText = messageText
        self.icon = icon
        
        self.location = location
        self.size = size
        self.timeToLive = timeToLive
        
        self.fadeInAnimationDuration = fadeInAnimationDuration
        self.fadeOutAnimationDuration = fadeOutAnimationDuration
        
        self.cornerRadius = cornerRadius
        self.backgroundTint = backgroundTint.withAlphaComponent(0.15)
        self.messageLabelBaselineOffsetFromBottomOfBezel = messageLabelBaselineOffsetFromBottomOfBezel
        self.messageLabelFont = messageLabelFont
        self.messageLabelColor = messageLabelColor
    }
}



public enum BezelTimeToLive {
    /// Bezel is shown for just a couple seconds
    case short
    
    /// Bezel if shown for several seconds
    case long
    
    /// Bezel is never hidden
    case forever
    
    /// Bezel is shown for an exact number of seconds
    case exactly(seconds: TimeInterval)
    
    
    var inSeconds : TimeInterval {
        switch self {
        case .short: return 2
        case .long: return 6
        case .forever: return .infinity
        case .exactly(let seconds): return seconds
        }
    }
}



public class BHBezelWindow : NSWindow {
    
//    lazy var messageTextLabel: NSTextField = {
//        let messageTextLabel = NSTextField(labelWithString: self.messageText)
//        messageTextLabel.font = NSFont.systemFont(ofSize: self.labelFontSize, weight: NSFont.Weight.regular)
//        messageTextLabel.wantsLayer = true
//        return messageTextLabel
//    }()
    
    private lazy var bezelContentView: BHBezelContentView = {
        let bezelContentView = BHBezelContentView(parameters: self.parameters)
        bezelContentView.wantsLayer = true
        bezelContentView.layer?.backgroundColor = parameters.backgroundTint.cgColor
        return bezelContentView
    }()
    
    var messageText: String { return parameters.messageText }
    fileprivate let parameters: BezelParameters
    
//    var labelBaselineOffsetFromBottomOfBezel: CGFloat { return parameters.messageLabelBaselineOffsetFromBottomOfBezel }
//    let labelFontSize: CGFloat { return parameters.messageLabelFont.pointSize }
    
//    public override var contentView: NSView? {
//        willSet {
//            newValue?.wantsLayer = true
//            newValue?.layer?.cornerRadius = parameters.cornerRadius
//            newValue?.layer?.masksToBounds = true
//        }
//    }
    
    
    public init(parameters: BezelParameters) {
        
        self.parameters = parameters
        
        let contentRect = parameters.location.bezelWindowContentRect(atSize: parameters.size)
        
        super.init(contentRect: contentRect,
                   styleMask: bezelStyleMask,
                   backing: .buffered,
                   defer: false)
        
        contentView = makeVisualEffectsBackingView()

        self.minSize = contentRect.size
        self.maxSize = contentRect.size
        
        self.isReleasedWhenClosed = false
        self.level = .dock
        self.ignoresMouseEvents = true
        self.appearance = NSAppearance(named: .vibrantDark)
        self.isOpaque = false
        self.backgroundColor = .clear
        
        addComponents()
    }
    
    
    private func addComponents() {
        guard let contentView = self.contentView else {
            assertionFailure("No content view when adding components to bezel!!")
            return
        }
        
        contentView.wantsLayer = true
        
        contentView.addSubview(bezelContentView)
        NSLayoutConstraint.activate([
            bezelContentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bezelContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bezelContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bezelContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

//        messageTextLabel.translatesAutoresizingMaskIntoConstraints = false
//        visualEffectView.addSubview(messageTextLabel)
//        NSLayoutConstraint.activate([
//            messageTextLabel.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor),
//            messageTextLabel.lastBaselineAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -labelBaselineOffsetFromBottomOfBezel)
//        ])
    }
    
    
    private func makeVisualEffectsBackingView() -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.wantsLayer = true
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .dark
        visualEffectView.state = .active
        visualEffectView.maskImage = .roundedRectMask(size: self.parameters.size.cgSize,
                                                      cornerRadius: self.parameters.cornerRadius)
        return visualEffectView
    }
}



private class BHBezelContentView: NSView {
    
    let parameters: BezelParameters
    
    override var allowsVibrancy: Bool { return true }
    
    init(parameters: BezelParameters) {
        self.parameters = parameters
        super.init(frame: NSRect(origin: .zero, size: parameters.size.cgSize))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }
        
        let textBounds = parameters.messageText.findBezelLabelBoundingBox(within: bounds,
                                                                          offsetFromBottom: parameters.messageLabelBaselineOffsetFromBottomOfBezel,
                                                                          font: parameters.messageLabelFont)
        
        if let icon = parameters.icon {
            let bezelSize = parameters.size.cgSize
            let bezelBounds = NSRect(origin: .zero, size: bezelSize)
            let bezelCenterX = bezelBounds.midX
            let messageLabelTop = textBounds.maxY;
            let halfwayBetweenLabelTopAndBezelTop = (bezelBounds.maxY + messageLabelTop) / 2
            
            let iconSize = NSSize(scaling: icon.size, toFitWithin: bezelSize * 0.6, approach: .scaleProportionallyDown)
            
            
            let iconBottomLeftCorner = NSPoint(x: bezelCenterX - (iconSize.width / 2),
                                               y: halfwayBetweenLabelTopAndBezelTop - (iconSize.height / 2))
            
            icon.draw(
                in: NSRect(origin: iconBottomLeftCorner, size: iconSize),
                from: .zero, // This is a "magic value" meaning "draw the whole image"
                operation: .sourceOver,
                fraction: 1, // "fraction" = "opacity"
                respectFlipped: true,
                hints: [.interpolation : NSNumber(value: NSImageInterpolation.high.rawValue)]
            )
        }

        context.setTextDrawingMode(.fill)
        context.draw(text: parameters.messageText,
                     at: textBounds.origin,
                     color: parameters.messageLabelColor.withAlphaComponent(parameters.messageLabelColor.alphaComponent * 0.8),
                     font: parameters.messageLabelFont)
    }
}



fileprivate extension String {
    fileprivate func findBezelLabelBoundingBox(within parentBounds: NSRect,
                                               offsetFromBottom: CGFloat,
                                               font: NSFont) -> NSRect {
        let attributedString = NSAttributedString(string: self, attributes: [.font : font])
        let textBounds = attributedString.boundingRect(with: parentBounds.size, options: [])
        let textBaselineY = offsetFromBottom
        let textLeftX = parentBounds.midX - textBounds.midX
        return NSRect(origin: NSPoint(x: textLeftX, y: textBaselineY), size: textBounds.size)
    }
    
    
    fileprivate func findBezelLabelTextStartPoint(within parentBounds: NSRect,
                                                  offsetFromBottom: CGFloat,
                                                  font: NSFont) -> NSPoint {
        return findBezelLabelBoundingBox(within: parentBounds, offsetFromBottom: offsetFromBottom, font: font).origin
    }
}



public enum BezelSize {
    case normal
}
extension BezelSize {
    public var width: CGFloat {
        switch self {
        case .normal:
            return 200
        }
    }
    
    public var height: CGFloat {
        switch self {
        case .normal:
            return 200
        }
    }
    
    public var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
}



public enum BezelLocation {
    case normal
}
extension BezelLocation {
    public func bezelWindowContentRect(atSize size: BezelSize) -> NSRect {
        switch self {
        case .normal:
            return screen?.lowerCenterRect(ofSize: size.cgSize) ?? NSRect(origin: NSPoint(x: 48, y: 48), size: size.cgSize)
        }
    }
    
    
    public var screen: NSScreen? {
        switch self {
        case .normal:
            return .main ?? NSScreen.screens.first
        }
    }
}



public extension NSScreen {
    
    private static let lowerCenterRectBottomOffset: CGFloat = 140
    
    public func lowerCenterRect(ofSize size: NSSize) -> NSRect {
        return NSRect(origin: NSPoint(x: self.frame.midX - (size.width / 2),
                                      y: self.frame.minY + NSScreen.lowerCenterRectBottomOffset),
                      size: size)
    }
}
