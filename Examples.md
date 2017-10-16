# Examples

### Providing `CarrotSession` with a `Socket`

A `CarrotSession` is initialized with something that conforms to the `Socket` protocol:

```swift
// MARK: - Socket
public protocol Socket: class {
  weak var eventDelegate: SocketDelegate? { get set }
  func open()
  func close()
  func send(data: Data) throws
}

// MARK: - SocketDelegate
public protocol SocketDelegate: class {
  func socketDidOpen()
  func socketDidClose(with code: Int?, reason: String?, wasClean: Bool?)
  func socketDidFail(with error: Error?)
  func socketDidReceive(data: Data)
}
``` 

This protocol allows you to use whatever implemention of a WebSocket that you'd like. All you have to do is conform the underlying implementation to the `Socket` protocol. The easiest way to do this is probably to wrap it within a new type that conforms to the `Socket` protocol.

### Using Facebook's [SocketRocket](https://github.com/facebook/SocketRocket)

Using the `CarrotSocket` as implemented below would allow you to do create a `CarrotSession` like this:

```swift
let carrotSocket = CarrotSocket(webSocket: SRWebSocket(url: URL(string: "http://78.125.0.209:8080/ws")))
let session = CarrotSession(socket: carrotSocket) { result in
  // handle stream messages received here
}
session.start()
```

#### `CarrotSocket`

```swift
import Foundation
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
      if let data = message.data(using: .utf8) {
        eventDelegate?.socketDidReceive(data: data)
      }
    default:
      break
    }
  }
}
```
