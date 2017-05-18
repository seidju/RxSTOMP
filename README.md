# RxSTOMP
## Down
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/iwasrobbed/Down/blob/master/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/v/RxSTOMP.svg?maxAge=2592000)]()
[![Swift](https://img.shields.io/badge/language-Swift-blue.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/OS-iOS-orange.svg)](https://developer.apple.com/ios/)

RxSTOMP is a variation of [STOMP protocol](https://stomp.github.io) using RxSwift and CocoaAsyncSocket.

## Installation

Quickly install using [CocoaPods](https://cocoapods.org): 

```ruby
pod 'RxSTOMP'
```
Or manually install:
1. Clone this repository
2. Copy `Core` folder to your project
3. Don't forget to install `RxSwift` dependency
4. Profit

There's also [Example](https://github.com/seidju/RxSTOMP/tree/master/Example/RxSTOMPExample) with simple usage how-to. 

## How to use
First of all don't forget to configure `host` and `port` of your STOMP server:
```swift
  RxSTOMPConfiguration.Network.host = "example.com"
  RxSTOMPConfiguration.Network.port = 7691
```
`RxSTOMPConfiguration` is a `struct`, where defined a lot of parameters, such as Read&Write timeouts, Tags, Queues, Host configuration

Then you need to initialize `RxSTOMPStream` object, which is responsible for handling socket connection and everything.
You can do it either just `init` with default initializer:
```swift
let rxStompStream = RxSTOMPStream()
```
Or using DI, for example `Swinject`:
```swift
   let container = Container() { container in        
        // Models
        container.register(RxSTOMPStreamProtocol.self) { _ in RxSTOMPStream() }
        
        // Views
        container.storyboardInitCompleted(ExampleViewController.self) {r,c in
            c.viewModel = r.resolve(ExampleViewModel.self)!
        }
        
        //View models
        container.register(ExampleViewModel.self) { r
            in ExampleViewModel(stompStream: r.resolve(RxSTOMPStreamProtocol.self)!)
        }
    }
```

Then after you `connect`, you just subscribe to two types of events: `state` and `incoming frames`:
```swift
self.rxStompStream.connect()

func subscribeToState() {
    self.rxStompStream.state
    .observeOn(SerialDispatchQueueScheduler(queue: RxSTOMPConfiguration.Queue.stompQueue, internalSerialQueueName: "stomp"))
    .filter { $0 == .connected } //after we connected -> do some stuff
    .subscribe(onNext: {[weak self] _ in
        guard let sSelf = self else { return }
        guard let login = sSelf.login, let passcode = sSelf.passcode else { return }
        sSelf.rxStompStream.auth(login: login, passcode: passcode)
    }).addDisposableTo(disposeBag)
}
    
//subscribe to incoming messages, like CONNECT, DISCONNECT, MESSAGE and etc...
 func subscribeToFrames() {
    self.rxStompStream.inputFrame
    .observeOn(SerialDispatchQueueScheduler(queue: RxSTOMPConfiguration.Queue.stompQueue, internalSerialQueueName: "stomp"))
    .subscribe(onNext: { inputFrame in
       print("input frame: \(inputFrame)")
    }).addDisposableTo(disposeBag)
}    

```

