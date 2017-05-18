//
//  ExampleViewModel.swift
//  RxSTOMPExample
//
//  Created by Pavel Shatalov on 18.05.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//

import RxSTOMP
import RxSwift
class ExampleViewModel {
    let stompStream: RxSTOMPStream
    fileprivate let disposeBag = DisposeBag()
    fileprivate var login: String?
    fileprivate var passcode: String?
    init(stompStream: RxSTOMPStream) {
        self.stompStream = stompStream
        self.subscribeToState()
        self.subscribeToFrames()
    }
    
    func connect(login: String, passcode: String) {
        self.stompStream.connect()
        self.login = login
        self.passcode = passcode
    }
    
    
    //subscribe to state
    //after we connected to socket
    //then we need to authorize on STOMP level
    fileprivate func subscribeToState() {
        self.stompStream.state
            .observeOn(SerialDispatchQueueScheduler(queue: RxSTOMPConfiguration.Queue.stompQueue, internalSerialQueueName: "stomp"))
            .filter { $0 == .connected}
            .subscribe(onNext: {[weak self] _ in
                guard let sSelf = self else { return }
                guard let login = sSelf.login, let passcode = sSelf.passcode else { return }
                sSelf.stompStream.auth(login: login, passcode: passcode)
            }).addDisposableTo(self.disposeBag)
    }
    
    //subscribe to incoming messages, like CONNECT, STOMP, DISCONNECT and etc...
    fileprivate func subscribeToFrames() {
        self.stompStream.inputFrame
            .observeOn(SerialDispatchQueueScheduler(queue: RxSTOMPConfiguration.Queue.stompQueue, internalSerialQueueName: "stomp"))
            .subscribe(onNext: { inputFrame in
                print("input frame: \(inputFrame)")
            }).addDisposableTo(self.disposeBag)
        
    }
}
