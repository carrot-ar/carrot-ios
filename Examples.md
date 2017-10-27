# Examples

### Initializing a `CarrotSession`

The first parameter in `CarrotSession`'s initializer is something that conforms to the [`Socket`](https://github.com/carrot-ar/carrot-ios/blob/master/Carrot/Networking/Socket.swift) protocol.

This protocol allows you to use whatever underlying implemention of a WebSocket that you'd like. All you have to do is conform the it to the `Socket` protocol. If you own the code, this should be trivial. If you don't own the underlying implementation, aka if you're using a third party library to interface with a WebSocket, the easiest way to do this is probably to wrap the third party WebSocket implementation within a new type that conforms to the `Socket` protocol.

The following shows how one might go about doing this.

### Using Facebook's [SocketRocket](https://github.com/facebook/SocketRocket)

Using the `CarrotSocket` as implemented below would allow you to do create a `CarrotSession` like this:

```swift
let webSocket = SRWebSocket(url: URL(string: "http://35.196.152.230:8080/ws")!)!
let carrotSocket = CarrotSocket(webSocket: webSocket)

carrotSession = CarrotSession(
  socket: carrotSocket,
  messageHandler: { result in 
    // handle receiving messages in here
  },
  errorHandler: { _, error in
    // handle receiving errors in here
  }
)

carrotSession.start()
```

#### `CarrotSocket`

`CarrotSocket` wraps an `SRWebSocket` and sets itself as the `SRWebSocket`'s delegate. It implements all of the methods required in the `Socket` protocol and and `SocketDelegate` protocol, respectively. It's important to note that `CarrotSession` expects all of these methods to be implemented correctly.

```swift
import Foundation
import Carrot
import SocketRocket

public class CarrotSocket: NSObject, Socket {
  
  // MARK: Lifecycle
  
  public init(webSocket: SRWebSocket) {
    socket = webSocket
    super.init()
    socket.delegate = self
  }
  
  // MARK: Socket
  
  public weak var eventDelegate: SocketDelegate?
  
  public func open() {
    socket.open()
  }
  
  public func close() {
    socket.close()
  }
  
  public func send(data: Data) throws {
    socket.send(data)
  }
  
  // MARK: Private
  
  private let socket: SRWebSocket
}

extension CarrotSocket: SRWebSocketDelegate {
  
  public func webSocketDidOpen(_ webSocket: SRWebSocket!) {
    eventDelegate?.socketDidOpen()
  }
  
  public func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
    eventDelegate?.socketDidClose(with: code, reason: reason, wasClean: wasClean)
  }
  
  public func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
    eventDelegate?.socketDidFail(with: error)
  }
  
  public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
    switch message {
    case let data as Data:
      eventDelegate?.socketDidReceive(data: data)
    case let message as String:
      eventDelegate?.socketDidReceive(data: Data(message.utf8))
    default:
      break
    }
  }
}
```
