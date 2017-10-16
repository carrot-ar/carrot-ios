# Examples

## Using a `CarrotSession`

A `CarrotSession` is initialized with something that conforms to the `Socket` protocol. This is just a simple abstraction of what a typical WebSocket interface might look like, and is used in order to allow you to use whatever WebSocket implementation you'd like to use under-the-hood.

Let's say you'd like to use Facebook's [SocketRocket](https://github.com/facebook/SocketRocket) as your WebSocket client implementation. In order to use it with a `CarrotSession`, you'd do something like this:

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
  
  // MARK: Internal
  
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
