<p align="center">
<img src="https://github.com/carrot-ar/carrot-ios/wiki/resources/Carrot@2x.png" alt="Carrot" width="300">
</p>
<p align="center">
    <a href="https://travis-ci.org/carrot-ar/carrot-ios">
        <img src="https://travis-ci.org/carrot-ar/carrot-ios.svg?branch=master" />
    </a>
    <img src="https://img.shields.io/badge/Swift-4.0-orange.svg" />
</p>

Carrot is an easy-to-use, real-time framework for building applications with multi-device AR capabilities. It works using WebSockets, Golang on the server-side, and a unique location tracking system based on iBeacons that we aptly named The Picnic Protocol. Using Carrot, multi-device AR apps can be created with high accuracy location tracking to provide rich and lifelike experiences. To see for yourself, check out Scribbles, a multiplayer drawing application made with Carrot. You can see a demo video [here](https://www.youtube.com/watch?v=6EVtb0pJPgk) and the code [here](https://github.com/carrot-ar/scribbles-ios).

|    | 🗂 Table of Contents |
|:--:|----------------------
| ✨ | [Features](#features)
| 📋 | [To-Do](#to-do)
| 🥗 | [The Picnic Protocol](#the-picnic-protocol)
| 🌎 | [Sessions](#sessions)
| ✉️ | [Messages](#messages)
| 🎙 | [Sending Messages to Carrot](#sending-messages-to-carrot)
| 📨 | [Receiving Messages from Carrot](#receiving-messages-from-carrot)

## ✨ Features

Here are some of what we think are Carrot's best features!

### 🤸‍♀️ Flexibility

Carrot is completely separate from any particular renderer, leaving you free to render however you'd like! Carrot is also agnostic to any specific WebSocket implementation, leaving you in control of how you'd like to go about your networking. Not to mention, messages allow for any kind of information to get passed around between clients and taken advantage of by custom controllers on the server-side.

### ⚡️ Speed

Carrot is real-time, lightning fast, and only getting faster thanks to some clever engineering on the backend. Carrot performs great even at around 30,000 requests per second, providing for a seamless multi-device AR experience.

### 🎛 Customizable

Carrot is heavily customizable thanks to `SessionDriver`. Implement your own state management and authentication protocol while still being able to take advantage of the many other benefits Carrot provides.

### 🚀 Lightweight

Carrot allows you to take an existing AR app and make it multi-device without writing too much code, allowing you to focus on perfecting and shipping your AR experience! Initialize a session, render incoming messages, broadcast local rendering events and forget about it!

## 📋 To-Do

First off, we'd love as much input from the community as possible! Please don't hesitate to create issues for any problems encountered and PRs to get discussions kicked off about features you'd like to see Carrot implement. It's very early on in the framework's lifespan and we'd like to take this in whatever direction the community wants 🙂

Here are a few things we have in mind (in no particular order):

- [ ] Swift Package Manager support
- [ ] Custom `SessionDriver` parity on the server-side
- [ ] Error recovery commands
- [ ] Header fields in `Socket` protocol
- [ ] Abstract away `PicnicProtocol` iBeacon functionality into a protocol
- [ ] More flexible route, endpoint & message paradigm (something like registering callbacks instead)

## 🥗 The Picnic Protocol

TODO

## 🌎 Sessions

Sessions are central to Carrot apps. A session is responsible for two things:

1. Managing authentication via some underlying protocol.
2. Providing a clean interface to the WebSocket used to relay messages to/from the Carrot server.

**When it comes to sessions, the word protocol is referring to a set of rules that governs the communications between computers on a network, not the Swift keyword.**

There are two types of sessions in Carrot: `CarrotSession` and `CustomCarrotSession`, and the difference between the two lies in the underlying protocol: 

|         Session        |    Protocol    |
| ---------------------- | ----------------
| `CarrotSession`        | `PicnicProtocol`
| `CustomCarrotSession`  | Custom protocol conforming to `SessionDriver`

You may use `start(stateDidChange: @escaping (Driver.State) -> Void)` and `end()` in order to start/end sessions, respectively. Let's take a closer look at `CarrotSession`, which is the easiest way to get started with Carrot and the Picnic Protocol.

### CarrotSession

Under the hood, `CarrotSession` uses the `PicnicProtocol` class as its `SessionDriver`:

```swift
public final class CarrotSession<T: Codable>: CustomCarrotSession<PicnicProtocol, T> {
    
  public init(
    socket: Socket,
    currentTransform: @escaping () -> matrix_float4x4?,
    messageHandler: @escaping (MessageResult<T>) -> Void,
    errorHandler: @escaping (PicnicProtocol.State?, Error) -> Void)
    
}
```

#### Socket

The `Socket` protocol, declared in `Socket.swift`, allows you to provide Carrot with whatever underlying implemention of a `WebSocket` you wish. For an example using Facebook's [SocketRocket](https://github.com/facebook/SocketRocket), see [CarrotSocket.swift](https://gist.github.com/gonzalonunez/ff23d36bef799a6a4d82d9c79d06771e).

### Example

Creating a `CarrotSession` within your `UIViewController` responsible for the `ARSKView`, for example, will look something like this:

```swift
carrotSession = CarrotSession(
      socket: socket,
      currentTransform: { [weak self] in
        return self?.sceneView.session.currentFrame?.camera.transform
      },
      messageHandler: { result in
        // handle receiving messages here
      },
      errorHandler: { _, error in
        // handle errors here
      })
```

### CustomCarrotSession

Opting for a `CustomCarrotSession` allows you to implement your own authentication protocol. This is designed for cases where maybe the Picnic Protocol is not a good fit for your multi-device AR experience. You're free to use whatever you'd like as long it conforms to the `SessionDriver` protocol, which we'll take a closer look at now.

#### ⚠️ Warning

At the time of writing, custom authentication protocols are not supported on the server-side. However, you can still use a `CustomCarrotSession` in order to implementing the Picnic Protocol in a different way or to layer other logic on top of `PicnicProtocol`.

#### SessionDriver

A `SessionDriver` has two responsibilities:

1. Managing state transitions via the `updateState(_:_:)` method.
2. Managing state upon receiving data via the `didReceive(_:_:_:)` method.

A `SessionDriver` is essentially a state-machine that responds to state changes and reacts to data that arrives via the WebSocket while in an unauthenticated state. Data that arrives while in an authenticated state gets passed to the session's `messageHandler` instead. Taking a look at `DriverState` should help clear this up.

##### DriverState

`SessionDriver` "states" are represented by the `DriverState` protocol:

```swift
public protocol DriverState {
  static var `default`: Self { get }
  
  var token: SessionToken? { get }
  var isAuthenticated: Bool { get }
}
```

Conforming to `DriverState` correctly is **very important**, as it decides whether or not messages get passed to the `SessionDriver` or the session's consumer-facing `messageHandler`. This decision depends on the current state's `isAuthenticated` flag.

### Example

For an concrete example of conforming to `SessionDriver`, take a look at `PicnicProtocol.swift`. It codifies the PicnicProtocol rules, standards, and state management into an object conforming to `SessionDriver` and uses `PicnicProtocolState` and its `DriverState`.

## ✉️ Messages

Messages in Carrot are how information about events gets encoded and packaged for the server-side to broadcast to other clients in the same session. In Swift, they are represented by the `Message<T: Codable>` struct:

```swift
public struct Message<T: Codable> {
  public var transform: matrix_float4x4?
  public var object: T
}
```

The `transform` property can be used to encode information about the position, orientation, and scale of objects pertaining to these encoded events, just like the corresponding property on [ARAnchor](https://developer.apple.com/documentation/arkit/aranchor/2867981-transform) in ARKit.

The generic `object` parameter allows you, the developer, to package any `Codable` information within a `Message`. This works nicely not only with `Codable` primitives like `String`, `Bool`, and `Int` but also with custom `Codable` classes, structs, and enums for example. Let's take a look at how this works in practice.

#### 💡 Tip

Using `enum` cases with associated values, you can describe different types of events within the same type, as long as the associated values are `Codable`. This allows you to represent the placement of different basic geometry nodes in an `ARSKView` with only one type (the custom conformance to `Codable` has been omitted for brevity):

```swift
enum Event: Codable {
  case label(String)
  case sphere(Int)
}

let message: Message<Event> = ...
```

[Little Bites of Cocoa #318](https://littlebitesofcocoa.com/318-codable-enums) is a great tutorial on how to make an `enum` with associated values conform to `Codable`.

### Example

Let's say you want your app to communicate to other clients that you've placed an `SKLabelNode` somewhere in your `ARSKView`, for example. This would allow you to broadcast this information to other devices and build a multi-device AR experience instead of a just standard and boring one 😛

You'd be able to use the following `struct` to encode all the information about an `SKLabelNode`:

```swift
struct LabelEvent: Codable {
  var text: String
}
```

Now, you'd be able to construct a `Message<LabelEvent>` after you've created the `ARAnchor` that represents the position and orientation of this `SKLabelNode` that's been placed by the user:

```swift
let anchor = ARAnchor(transform: sceneView.session.currentFrame!.camera.transform)
let message = Message(transform: anchor.transform, object: LabelEvent(text: "🥕"))
// Send the message via my `CarrotSession`
```

Upon receiving the message, another client would be able to decode it and have all the information necessary to render the `SKLabelNode`. We'll go over both the sending and receiving of messages in the following sections.

## 🎙 Sending Messages to Carrot

Sending messages happens via `public func send(message: Message<Object>, to endpoint: Endpoint) throws`. On top of the actual `Message<Object>` itself, this method requires an `Endpoint`. This `Endpoint` is how the server-side knows what controller to route the message to. 

### Example

Using the `LabelEvent` we defined earlier, sending a message from the `UIViewController` responsible for the `ARSKView` would look something like this:

```swift
guard let currentTransform = sceneView.session.currentFrame?.camera.transform else { return }

let message = Message(
      transform: currentTransform,
      object: LabelEvent(text: "🥕"))
    
do {
  try carrotSession.send(message: message, to: "draw")
} catch {
  // handle the error here
}
```

## 📨 Receiving Messages from Carrot

Receiving messages happens via the `messageHandler` closure of type `(MessageResult<T>) -> Void` that you provide in the initializer of a session. Messages get passed to this closure when the underlying `SessionDriver`'s state is an authenticated one.

#### 💡 Tip

Thanks to first class functions in Swift, you might want to do something like this when you initialize your session:

```swift
carrotSession = CarrotSession(
      socket: socket,
      currentTransform: { [weak self] in
        return self?.sceneView.session.currentFrame?.camera.transform
      },
      messageHandler: didReceive,
      errorHandler: { _, error in
        // handle errors here
      })
      
func didReceive(messageResult result: MessageResult<LabelEvent>) {
  switch result {
    case let .success(message, endpoint):
      // handle message here
    case let .error(error):
      // handle error here
   }
}
```

### Example

Here's an example of parsing a `MessageResult` and rendering it accordingly using the same function we define in the tip above:

```swift
var labels = [ARAnchor: LabelEvent]()

func didReceive(messageResult result: MessageResult<LabelEvent>) {
  switch result {
    case let .success(message, _):
       // In this example, we ignore the endpoint since there's only one. We also know every `LabelEvent` is tied to a transform.
       guard let transform = message.transform else { return }
       let anchor = ARAnchor(transform: transform)
       labels[anchor] = message.object
       sceneView.add(anchor: anchor)
    case let .error(error):
      // handle error here
   }
}
```

Now, in the same `UIViewController`, we can implement `ARSKViewDelegate`'s `view(_ view: ARSKView, nodeFor anchor: ARAnchor)`:

```swift
func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
   guard let labelEvent = labels[anchor] else { return nil }
   let labelNode = SKLabelNode(text: labelEvent.text)
   // If we wanted to, we can give `LabelEvent` a way to codify the following alignment modes as well! 
   labelNode.horizontalAlignmentMode = .center
   labelNode.verticalAlignmentMode = .center
   return labelNode
 }
```
