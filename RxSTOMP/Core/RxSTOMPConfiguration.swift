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
        public static var host: String = "localhost"
        public static var port: UInt16 = 7891
    }
    
    public struct Queue {
        public static let stompQueue = DispatchQueue(label: "stomp")
    }
    
    public struct Timeouts {
        public static var stompWriteStream: TimeInterval = -1
        public static var stompReadStart: TimeInterval = 10
        public static var stompReadStream: TimeInterval = -1
    }
    
    public struct Tags {
        static let tagReadStart = 100
        static let tagReadStream = 101
        static let tagWriteStart = 200
        static let tagWriteStop = 201
        static let tagWriteStream = 202
    }
}
