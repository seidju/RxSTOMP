//
//  Created by Pavel Shatalov on 03.03.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//
//

import CocoaAsyncSocket
import RxSwift

/*
This is implementation of STOMP protocol https://stomp.github.io using RxSwift
It uses two Observable's for state and incoming frame
All who interested in it need just to subscribe to it
*/


//MARK: - Connection state
public enum StompState {
    case connecting
    case connected
    case disconnected
    case auth
}

//MARK: - Protocol for DI
public protocol RxSTOMPStreamProtocol {
    var inputFrame: Observable<RxSTOMPFrame> { get }
    var state: Observable<StompState> { get }
    func connect()
    func auth(login: String, passcode: String)
    func disconnect()
    func sendFrame(frame: RxSTOMPFrame)
}


public class RxSTOMPStream: NSObject, RxSTOMPStreamProtocol {
    
//MARK: - accessible properties
    public var inputFrame: Observable <RxSTOMPFrame> {
        return inputFrameSubject.asObservable()
    }
    public var state: Observable<StompState> {
        return stateSubject.asObservable()
    }

//MARK: - Private
    fileprivate var inputFrameSubject = PublishSubject<RxSTOMPFrame>()
    fileprivate var stateSubject = PublishSubject<StompState>()
    fileprivate let parser = RxSTOMPParser()
    fileprivate var socket: GCDAsyncSocket!
    fileprivate var heartbeatTimer: Timer = Timer()
    fileprivate var bytesRead: Int = 0
    fileprivate var bytesWritten: Int = 0

    
//MARK: - Initializer
    override public init() {
        super.init()
        self.commonInit()
    }
    
    private func commonInit() {
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: RxSTOMPConfiguration.Queue.stompQueue, socketQueue: RxSTOMPConfiguration.Queue.stompQueue)
    }

    
//MARK: - Basic functions
    public func connect() {
        guard let socket = self.socket else { return }
        self.stateSubject.on(.next(.connecting))
        do {
            try socket.connect(toHost: RxSTOMPConfiguration.Network.host, onPort: RxSTOMPConfiguration.Network.port, withTimeout: 15.0)
        } catch {
            self.stateSubject.on(.next(.disconnected))
            print("ERROR! Couldn't connect to socket: \(error)")
        }
    }
    
    public func disconnect() {
        let disconnectFrame = RxSTOMPFrame(command: .disconnect, headers: [.receipt(receipId: "foo")])
        self.sendFrame(frame: disconnectFrame)
        self.socket.disconnect()
    }
    
    public func auth(login: String, passcode: String) {
        let device_id = UIDevice.current.identifierForVendor!.uuidString
        let connectionFrame = RxSTOMPFrame(command: .connect, headers: [.host(host: RxSTOMPConfiguration.Network.host), .acceptVersion(version: "1.2"), .login(login: login), .passcode(passcode: passcode), .device_id(device_id: device_id), .heartBeat(value: "10000,10000"), .receipt(receipId: UUID().uuidString)])
        self.sendFrame(frame: connectionFrame)
    }
}

//MARK: - Utility methods
extension RxSTOMPStream {
    public func sendFrame(frame: RxSTOMPFrame) {
        print("SEND COMMAND: \(frame.description)")
        RxSTOMPConfiguration.Queue.stompQueue.async { [weak self] in
            guard let sSelf = self else { return }
            guard let socket = sSelf.socket else { return }
            if let data = frame.description.data(using: .utf8) {
                socket.write(data, withTimeout: RxSTOMPConfiguration.Timeouts.stompWriteStream, tag: RxSTOMPConfiguration.Tags.tagWriteStream)
            }
        }
    }
    
    fileprivate func validate(frames: [RxSTOMPFrame]) {
        guard let socket = self.socket else { return }
        for frame in frames {
            self.parseSystemMessages(frame: frame)
            self.inputFrameSubject.on(.next(frame))
            socket.readData(withTimeout: RxSTOMPConfiguration.Timeouts.stompReadStream, tag: RxSTOMPConfiguration.Tags.tagReadStream)
        }
    }
    
    fileprivate func parseSystemMessages(frame: RxSTOMPFrame) {
        switch frame.command {
        case .connected:
            self.stateSubject.on(.next(.auth))
            for header in frame.headers {
                if header.key == "heart-beat" {
                    self.setupHeartBeatTimer(withHeartBeat: header.value)
                    print("heart beat is :\(header.value)")
                }
            }
        case .error: print("DID RECEIVE STOMP ERROR: \(frame.description)")
        default: break
        }
    }
    
    
    private func setupHeartBeatTimer(withHeartBeat hearBeat: String) {
        guard let ping = hearBeat.components(separatedBy: ",").first else { return }
        guard let pingTime = Double(ping) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else { return }
            sSelf.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: (pingTime / 1000) * 0.8, repeats: true, block: {_ in
              RxSTOMPConfiguration.Queue.stompQueue.async {
                    guard let socket = sSelf.socket else { return }
                    if let heartBeatData = "\n".data(using: .utf8) {
                        socket.write(heartBeatData, withTimeout: RxSTOMPConfiguration.Timeouts.stompWriteStream, tag: RxSTOMPConfiguration.Tags.tagWriteStream)
                    }
                }
            })
        }
    }
}

//MARK: - GCDAsyncSocketDelegate methods
extension RxSTOMPStream: GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        if sock.isConnected {
            print("********SOCKET DID CONNECT TO HOST: \(host) ***********")
            self.stateSubject.on(.next(.connected))
            sock.readData(withTimeout: RxSTOMPConfiguration.Timeouts.stompReadStream, tag: RxSTOMPConfiguration.Tags.tagReadStart)
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let incomingCommand = self.parser.parse(data: data)
        self.validate(frames: incomingCommand)
        if sock.isDisconnected {
            sock.readData(withTimeout: RxSTOMPConfiguration.Timeouts.stompReadStart, tag: RxSTOMPConfiguration.Tags.tagReadStart)
        } else if sock.isConnected {
            sock.readData(withTimeout: RxSTOMPConfiguration.Timeouts.stompReadStream, tag: RxSTOMPConfiguration.Tags.tagReadStream)
        }
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("*********SOCKET DID DISCONNECT WITH ERROR: \(err?.localizedDescription ?? "NO ERROR")")
        self.stateSubject.on(.next(.disconnected))
        self.heartbeatTimer.invalidate()
    }
}
