# BHBezelNotification #

You know those dark, vibrant square notifications macOS does when you change the volume 'n' stuff? This is like that, but you can actually use it in your projects.

<img src="https://i.imgur.com/zwIa2K4.png" width="705" />


## Usage ##

This is designed to strike a balance between ease-of-use and customizability. For instance, this is the primary way it is intended to be used in the general case:

```Swift
BHBezelNotification.show(message: "Loading...", icon: .myLoadingIcon)
```


But it can be customized heavily if preferred, like this:

```Swift
BHBezelNotification.show(messageText: "Loading...",
                         icon: .myLoadingIcon,

                         location: .normal,
                         size: .normal,

                         timeToLive: .long,
                         fadeInAnimationDuration: 0.1,
                         fadeOutAnimationDuration: 1,

                         cornerRadius: 10,
                         tint: NSColor = BezelParameters.defaultBackgroundTint,
                         messageLabelFont: NSFont(name: "American Typewriter", size: 20)!,
                         messageLabelColor: .magenta,

                         afterHideCallback: { print("Bezel was presented successfully") }
)
```

All these parameters (aside from the callback) can be encapsulated in a `BezelParameters` object. This is useful for keeping pre-defned bezels, serializing them for user-customization, etc.
