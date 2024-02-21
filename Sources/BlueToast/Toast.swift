//
//  Toast.swift
//
//
//  Created by The Northstar✨ System on 2024-02-16.
//

import Combine
import SwiftUI

import CrossKitTypes
import FunctionTools
import SimpleLogging



public protocol ToastStyle {
    
    
    func body(_ configuration: Configuration) -> Body
    
    
    
    associatedtype Body: View
}



// MARK: - ToastConfiguration

public struct ToastConfiguration {
    public let text: AttributedString
    public let duration: Duration?
    public let icon: Image?
    public let action: Action?
    
    
    init(text: AttributedString, duration: Duration?, icon: Image?, action: Action?) {
        self.text = text
        self.duration = duration
        self.icon = icon
        self.action = action
    }
    
    
    init<ToastText>(text: ToastText, duration: Duration?, icon: Image?, action: Action?)
    where ToastText: StringProtocol
    {
        self.init(text: AttributedString(text),
                  duration: duration,
                  icon: icon,
                  action: action)
    }
    
    
    
    public enum Duration {
        
        /// The toast is being shown for a brief moment to confirm that an action occurred, without remaining long enough allowing the user to read more than a couple words
        case actionFeedback
        
        /// The toast is explaining something to the user, who will be reading a notable amount of text on the toast
        case importantText
        
        /// The toast alerts the user of something so critical that they must be able to see the toast even if they weren't using the device at the time it was presented
        case criticalAlert
    }
    
    
    
    public struct Action {
        let label: String
        let userDidInteract: BlindCallback
    }
}



public extension ToastStyle {
    typealias Configuration = ToastConfiguration
}



// MARK: - API

public extension View {
    func toast(
        isPresented: Binding<Bool>,
        text: AttributedString,
        duration: ToastConfiguration.Duration? = nil,
        icon: Image? = nil,
        action: ToastConfiguration.Action? = nil)
    -> some View
    {
        modifier(Toast(isPresented: isPresented, configuration: .init(text: text, duration: duration, icon: icon, action: action)))
    }
    
    
    func toast<ToastText>(
        isPresented: Binding<Bool>,
        text: ToastText,
        duration: ToastConfiguration.Duration? = nil,
        icon: Image? = nil,
        action: ToastConfiguration.Action? = nil)
    -> some View
    where ToastText: StringProtocol
    {
        toast(isPresented: isPresented,
              text: AttributedString(text),
              duration: duration,
              icon: icon,
              action: action)
    }
}



public extension View {
    func toastStyle<Style>(_ toastStyle: Style) -> some View 
    where Style: ToastStyle
    {
        environment(\.toastStyle, toastStyle)
    }
}



// MARK: - Implementation

private struct Toast: ViewModifier {
    
    @Environment(\.toastStyle)
    private var toastStyle
    
    @State
    private var disappearDate: Date = .distantPast
    
    @State
    private var timerStorage: Set<AnyCancellable> = []
    
    @Binding
    var isPresented: Bool
    
    let configuration: ToastStyle.Configuration
    
    
    #if DEBUG
    @Environment(\.debugOverlay)
    private var debugOverlay
    
    @State
    private var _debug_appearCount = 0
    #endif
    
    
    func body(content parent: Content) -> some View {
        parent
            .overlay {
                ZStack {
                    #if DEBUG
                    if debugOverlay.shouldShow {
                        _debug_infoView
                    }
                    #endif
                    
                    if isPresented {
                        AnyView(toastStyle.body(configuration))
                        
                            .transition(.move(edge: .bottom).animation(.bouncy))
                            .onAppear {
                                #if DEBUG
                                _debug_appearCount += 1
                                #endif
                                
                                disappearDate = configuration.disappearDateIfAppearingNow()
                            }
                            .task {
                                Timer.publish(every: configuration.actualDuration.inSeconds / 12, on: .main, in: .modalPanel)
                                    .sink { now in
                                        if now >= disappearDate {
                                            wrapUpDippear()
                                        }
                                    }
                                    .store(in: &timerStorage)
                            }
                            .onDisappear {
                                wrapUpDippear()
                            }
                    }
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(true)
                }
            }
    }
    
    
    
    private func wrapUpDippear() {
        isPresented = false
        timerStorage = []
        disappearDate = .distantPast
    }
    
    
    #if DEBUG
    @ViewBuilder
    var _debug_infoView: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading) {
                _debug_infoItem("isPresented", value: isPresented)
                _debug_infoItem("Appearance count", value: _debug_appearCount, format: .number)
                _debug_infoItem("Disappear date", value: disappearDate)
            }
            .font(.caption)
//            .background(Color(white: 0.6).blendMode(.darken))
            
            Rectangle().fill(.clear)
            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .foregroundStyle(.white)
    }
    
    
    func _debug_infoItem<Value, Format>(_ title: String, value: Value, format: Format) -> some View
    where Value: Equatable,
          Format: FormatStyle,
          Format.FormatInput == Value,
          Format.FormatOutput == String
    {
        Text("\(title): \(Text("\(value, format: format)").bold().monospacedDigit())")
    }
    
    
    func _debug_infoItem<Value>(_ title: String, value: Value) -> some View {
        Text("\(title): \(Text(String(describing: value)).bold().monospacedDigit())")
    }
    #endif
}



private extension ToastStyle.Configuration {
    func disappearDateIfAppearingNow() -> Date {
        disappearDate(appearingAt: .now)
    }
    
    
    func disappearDate(appearingAt appearDate: Date) -> Date {
        actualDuration.disappearDate(appearingAt: appearDate)
    }
    
    
    var actualDuration: Duration {
        duration ?? .default
    }
}



private extension ToastStyle.Configuration.Duration {
    func disappearDate(appearingAt appearDate: Date) -> Date {
        switch self {
        case .actionFeedback,
                .importantText:
            appearDate + inSeconds
            
        case .criticalAlert:
                .distantFuture
        }
    }
    
    
    var inSeconds: TimeInterval {
        switch self {
        case .actionFeedback: 2
        case .importantText: 6
        case .criticalAlert: 60 * 60 * 24 * 365.242189 // 1 year
        }
    }
    
    
    
    static let `default` = actionFeedback
}



// MARK: Environment

private extension EnvironmentValues {
    var toastStyle: any ToastStyle {
        get { self[ToastStyle.EnvironmentKey.self] }
        set { self[ToastStyle.EnvironmentKey.self] = newValue }
    }
}



private extension ToastStyle {
    typealias EnvironmentKey = ToastStyleEnvironmentKey
}



private struct ToastStyleEnvironmentKey: EnvironmentKey {
    static var defaultValue: any ToastStyle {
        DefaultToastStyle()
    }
}



// MARK: - Builtin toasts

// MARK: - Default

#if canImport(AppKit)
public typealias DefaultToastStyle = SystemBezelToastStyle
#else
public typealias DefaultToastStyle = BezelToastStyle
#endif



public extension ToastStyle where Self == DefaultToastStyle {
    static var `default`: Self { .init() }
}



// MARK: System Bezel

#if !canImport(AppKit)
@available(*, unavailable, renamed: "BezelToastStyle", message: """
    `SystemBezelToastStyle` is only available on macOS because of how it escapes the app window.
    
    If you want a similar effect within your app, try using `BezelToastStyle` instead.
    """)
public typealias SystemBezelToastStyle = BezelToastStyle
#else
public struct SystemBezelToastStyle: ToastStyle {
    
    private static var notificationLifecyclePublishers: Set<AnyCancellable> = []
    
    private let initialParameters: Parameters
    
    
    public init(parameters: Parameters = .init(messageText: "")) {
        self.initialParameters = parameters
    }
    
    
    
    public func body(_ configuration: Configuration) -> some View {
        Rectangle()
            .fill(.clear)
            .onAppear {
                SystemBezelNotification.show(with: parameters(with: configuration))
                    .sink { _ in }
                    .store(in: &SystemBezelToastStyle.notificationLifecyclePublishers)
            }
    }
    
    
    private func parameters(with configuration: Configuration) -> Parameters {
        var parameters = self.initialParameters
        
        parameters.messageText = configuration.text.description
        parameters.timeToLive = .init(configuration.actualDuration)
        
        if let icon = configuration.icon {
            parameters.icon = icon.nativeImage()
        }
        
        return parameters
    }
    
    
    
    public typealias Parameters = SystemBezelNotification.Parameters
}



private extension SystemBezelNotification.TimeToLive {
    init(_ duration: ToastStyle.Configuration.Duration) {
        self = switch duration {
        case .actionFeedback: .short
        case .importantText: .long
        case .criticalAlert: .forever
        }
    }
}



public extension ToastStyle where Self == SystemBezelToastStyle {
    
    static var systemBezel: Self { Self.init() }
    
    
    static func systemBezel(_ parameters: SystemBezelToastStyle.Parameters) -> Self { Self.init(parameters: parameters) }
    
    
    static func systemBezel(
        messageText: String,
        icon: Image? = nil,
        
        location: SystemBezelNotification.Location = SystemBezelNotification.Parameters.defaultLocation,
        size: SystemBezelNotification.Size = SystemBezelNotification.Parameters.defaultSize,
        
        timeToLive: SystemBezelNotification.TimeToLive = SystemBezelNotification.Parameters.defaultTimeToLive,
        fadeInAnimationDuration: TimeInterval = SystemBezelNotification.Parameters.defaultFadeInAnimationDuration,
        fadeOutAnimationDuration: TimeInterval = SystemBezelNotification.Parameters.defaultFadeOutAnimationDuration,
        
        cornerRadius: CGFloat = SystemBezelNotification.Parameters.defaultCornerRadius,
        tint: Color = Color(SystemBezelNotification.Parameters.defaultBackgroundTint),
        messageLabelFont: NSFont = SystemBezelNotification.Parameters.defaultMessageLabelFont,
        messageLabelColor: Color = Color(SystemBezelNotification.Parameters.defaultMessageLabelColor))
    -> Self
    {
        systemBezel(.init(
            messageText: messageText,
            icon: icon?.nativeImage(),
            location: location,
            size: size,
            timeToLive: timeToLive,
            fadeInAnimationDuration: fadeInAnimationDuration,
            fadeOutAnimationDuration: fadeOutAnimationDuration,
            cornerRadius: cornerRadius,
            backgroundTint: .init(tint),
            messageLabelFont: messageLabelFont,
            messageLabelColor: .init(messageLabelColor)))
    }
}



#Preview("System bezel") {
    ToastPreview {
        SystemBezelToastStyle()
    }
}
#endif



// TODO: Bezel



// MARK: Snackbar

public struct SnackbarToastStyle: ToastStyle {
    
    public func body(_ configuration: Configuration) -> some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(.clear)
            
            HStack {
                Text(configuration.text)
                
                if let action = configuration.action {
                    Button(action.label, action: action.userDidInteract)
                        .buttonStyle(.link)
                }
            }
            .font(.body)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.ultraThinMaterial.blendMode(.multiply))
                    .shadow(radius: 6, y: 2)
            }
            .padding()
            
            .preferredColorScheme(.dark)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        .transition(.move(edge: .bottom).animation(.bouncy))
    }
}



public extension ToastStyle where Self == SnackbarToastStyle {
    static var snackbar: Self { Self.init() }
}



// MARK: Preview

#Preview("Snackbar") {
    ToastPreview {
        SnackbarToastStyle()
    }
}



// MARK: - ToastPreview

private struct ToastPreview<ToastStyleKind: ToastStyle>: View {
    
    @State
    private var show = true
    
    let demoToast: () -> ToastStyleKind
    
    var body: some View {
        ZStack {
            Toggle("Show", isOn: $show)
            
            Rectangle()
                .fill(.clear)
                .frame(width: 640, height: 480)
                .overlay {
                    if show {
                        demoToast()
                            .body(.init(text: "Test toast",
                                        duration: .criticalAlert,
                                        icon: nil,
                                        action: .init(label: "Action!", userDidInteract: null)))
//                            .animation(.bouncy, value: show)
                    }
                }
        }
    }
}
