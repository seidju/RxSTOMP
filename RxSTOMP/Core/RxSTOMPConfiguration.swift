//
//  StompConstants.swift
//
//  Created by Pavel Shatalov on 28.02.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//

import Foundation

//Simple configuration
public struct RxSTOMPConfiguration {
    public struct Network {
        static var host: String = "localhost"
        static var port: UInt16 = 7891
    }
    
    public struct Queue {
        static let stompQueue = DispatchQueue(label: "stomp")
    }
    
    public struct Timeouts {
        static let stompWriteStream: TimeInterval = -1
        static let stompReadStart: TimeInterval = 10
        static let stompReadStream: TimeInterval = -1
    }
    
    public struct Tags {
        static let tagReadStart = 100
        static let tagReadStream = 101
        static let tagWriteStart = 200
        static let tagWriteStop = 201
        static let tagWriteStream = 202
    }
}
