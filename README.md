# BHBezelNotification #

You know those dark, vibrant square notifications macOS does when you change the volume 'n' stuff? This is like that, but you can actually use it in your projects.

<img src="https://i.imgur.com/zwIa2K4.png" width="705" />

Note that this does _not_ use any secret system APIs (but instead creates its own bezel notifications from scratch), so this cannot interact with nor affect system bezel notifications.


## Try it out! ##

To try out BHBezelNotification without instaling it into your own project first, you can use [this demo app we put together](https://github.com/BenLeggiero/BHBezelNotification-Demo-App)!


## Usage ##

This is designed to strike a balance between ease-of-use and customizability. For instance, this is the primary way it is intended to be used in the general case:

```Swift
BHBezelNotification.show(messageText: "Loading...", icon: .myLoadingIcon)
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
                         tint: BezelParameters.defaultBackgroundTint,
                         messageLabelFont: NSFont(name: "American Typewriter", size: 20)!,
                         messageLabelColor: .magenta,

                         afterHideCallback: { print("Bezel was presented successfully") }
)
```

All these parameters (aside from the callback) can be encapsulated in a `BezelParameters` object. This is useful for keeping pre-defned bezels, serializing them for user-customization, etc.
