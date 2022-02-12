//
//  BHBezelNotification.swift
//  Bezel Notification
//
//  Created by Ky Leggiero on 2017-11-09.
//  Version 2 created by Ky Leggiero on 2022-02-12.
//  Copyright © 2022 Ky Leggiero BH-1-PS
//

import Cocoa
import Combine

import CrossKitTypes
import FunctionTools



/// The style mask used on all bezel windows
private let bezelStyleMask: NSWindow.StyleMask = [.borderless]

/// All currently-showing bezel windows
private var bezelWindows = Set<BezelNotification.Window>()



/// The public interface for showing a notification bezel
public enum BezelNotification {
    // Empty on-purpose; all members are static
}



public extension BezelNotification {
    
    typealias AfterHideCallback = BlindCallback
    
    /// Shows a BHBezel notification using the given parameters.
    /// See `BHBezelParameters` for documentation of each parameter.
    ///
    /// If you want to manually dismiss th enotification, rather than trusting the time to live, you can give a very
    /// large nubmer for `timeToLive` and call the resulting delegate's `donePresentingBezel()` function.
    ///
    /// - Returns: A delegate that allows control of the bezel after it's shown
    /// - SeeAlso: BezelNotification.Parameters
    @discardableResult
    static func show(messageText: String,
                     icon: NativeImage? = nil,
                     
                     location: Location = Parameters.defaultLocation,
                     size: Size = Parameters.defaultSize,
                     
                     timeToLive: TimeToLive = Parameters.defaultTimeToLive,
                     fadeInAnimationDuration: TimeInterval = Parameters.defaultFadeInAnimationDuration,
                     fadeOutAnimationDuration: TimeInterval = Parameters.defaultFadeOutAnimationDuration,
                     
                     cornerRadius: CGFloat = Parameters.defaultCornerRadius,
                     tint: NSColor = Parameters.defaultBackgroundTint,
                     messageLabelFont: NSFont = Parameters.defaultMessageLabelFont,
                     messageLabelColor: NSColor = Parameters.defaultMessageLabelColor,
                     
                     afterHideCallback: @escaping AfterHideCallback = {}
    ) -> LifecyclePublisher {
        
        return self.show(
            with: Parameters(
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
    /// large nubmer for `timeToLive` (e.g. `.infinity`) and call the resulting delegate's `donePresentingBezel()`
    /// function.
    ///
    /// - Returns: A delegate that allows control of the bezel after it's shown
    /// - SeeAlso: ``BezelNotification.Parameters``
    static func show(with parameters: Parameters,
                     afterHideCallback: @escaping AfterHideCallback = null)
    -> LifecyclePublisher
    {
        let publisher = CurrentValueSubject<LifecycleStage, Never>(.willAppear)
        
        DispatchQueue.main.async {
            let bezelWindow = Window(parameters: parameters)
            bezelWindows.insert(bezelWindow)
            
            publisher.send(.appearing)
            bezelWindow.fadeIn(duration: parameters.fadeInAnimationDuration,
                               presentationFunction: .orderFrontRegardless)
            {
                publisher.send(.presented)
            }
            
            Timer.scheduledTimer(withTimeInterval: parameters.timeToLive.inSeconds, repeats: false) { _ in
                publisher.send(.disappearing)
                bezelWindow.fadeOut(duration: bezelWindow.parameters.fadeOutAnimationDuration,
                                    closeSelector: .close)
                {
                    bezelWindows.remove(bezelWindow)
                    publisher.send(.didDisappear)
                }
            }
        }
        
        return publisher.eraseToAnyPublisher()
    }
}



public extension BezelNotification {
    typealias LifecyclePublisher = AnyPublisher<LifecycleStage, Never>
}



public extension BezelNotification {
    
    /// A stage in the lifecycle of a bezel notification
    enum LifecycleStage {
        
        /// The bezel notification is not showing and will appear soon
        case willAppear
        
        /// The bezel notification's appearance animation is in-progress
        case appearing
        
        /// The bezel notification has finished its appearance animation and is statically on-screen
        case presented
        
        /// The bezel notification's disappearance animation is in-progress
        case disappearing
        
        /// The bezel notification has finished its disappearance animation and is no longer on-screen.
        /// This typically indicates that this instance of a bezel notification will not appear again.
        case didDisappear
    }
}



/// A set of parameters used to configure and present a bezel notification
public extension BezelNotification {
    struct Parameters {
        
        public static let defaultLocation: Location = .normal
        public static let defaultSize: Size = .normal
        public static let defaultTimeToLive: TimeToLive = .short
        
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
        let location: Location
        
        /// The size of the bezel notification
        let size: Size
        
        /// The number of seconds to display the bezel notification on the screen
        let timeToLive: TimeToLive
        
        
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
                    
                    location: Location = defaultLocation,
                    size: Size = defaultSize,
                    timeToLive: TimeToLive = defaultTimeToLive,
                    
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
    
    
    
    /// How long a bezel notification should stay on screen
    enum TimeToLive {
        
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
    
    
    
    /// The window used to present a bezel notification.
    /// If you _really_ need minute control, you may use this.
    class Window : NSWindow {
        
        private lazy var bezelContentView: ContentView = {
            let bezelContentView = ContentView(parameters: self.parameters)
            bezelContentView.wantsLayer = true
            bezelContentView.layer?.backgroundColor = parameters.backgroundTint.cgColor
            return bezelContentView
        }()
        
        var messageText: String { return parameters.messageText }
        
        fileprivate let parameters: Parameters
        
        
        /// Creates a new bezel window with the given parameters
        ///
        /// - Parameter parameters: Those parameters that dictate how this window appears
        public init(parameters: Parameters) {
            
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
    
    
    
    /// The view powering the `BezelWindow`'s appearance.
    /// If you _really, really_ need _extreme_ control, you may use this. Don't, though, if you can avoid it.
    class ContentView: NSView {
        
        let parameters: Parameters
        
        override public var allowsVibrancy: Bool { return true }
        
        public init(parameters: Parameters) {
            self.parameters = parameters
            super.init(frame: NSRect(origin: .zero, size: parameters.size.cgSize))
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) not implemented")
        }
        
        override public func draw(_ dirtyRect: NSRect) {
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
}


private extension String {
    func findBezelLabelBoundingBox(within parentBounds: NSRect,
                                   offsetFromBottom: CGFloat,
                                   font: NSFont) -> NSRect {
        let attributedString = NSAttributedString(string: self, attributes: [.font : font])
        let textBounds = attributedString.boundingRect(with: parentBounds.size, options: [])
        let textBaselineY = offsetFromBottom
        let textLeftX = parentBounds.midX - textBounds.midX
        return NSRect(origin: NSPoint(x: textLeftX, y: textBaselineY), size: textBounds.size)
    }
    
    
    func findBezelLabelTextStartPoint(within parentBounds: NSRect,
                                      offsetFromBottom: CGFloat,
                                      font: NSFont) -> NSPoint {
        return findBezelLabelBoundingBox(within: parentBounds, offsetFromBottom: offsetFromBottom, font: font).origin
    }
}



public extension BezelNotification {
    /// The semantic size of a bezel notification
    enum Size {
        case normal
    }
}



internal extension BezelNotification.Size {
    
    private var width: CGFloat {
        switch self {
        case .normal:
            return 200
        }
    }
    
    
    private var height: CGFloat {
        switch self {
        case .normal:
            return 200
        }
    }
    
    
    var cgSize: CGSize {
        CGSize(width: width, height: height)
    }
}



public extension BezelNotification {
    /// The semantic location of a bezel notification
    enum Location {
        case normal
    }
}



internal extension BezelNotification.Location {
    func bezelWindowContentRect(atSize size: BezelNotification.Size) -> NSRect {
        switch self {
        case .normal:
            return screen?.lowerCenterRect(ofSize: size.cgSize) ?? NSRect(origin: NSPoint(x: 48, y: 48), size: size.cgSize)
        }
    }
    
    
    var screen: NSScreen? {
        switch self {
        case .normal:
            return .main ?? NSScreen.screens.first
        }
    }
}



private extension NSScreen {
    
    private static let lowerCenterRectBottomOffset: CGFloat = 140
    
    func lowerCenterRect(ofSize size: NSSize) -> NSRect {
        return NSRect(origin: NSPoint(x: self.frame.midX - (size.width / 2),
                                      y: self.frame.minY + NSScreen.lowerCenterRectBottomOffset),
                      size: size)
    }
}
