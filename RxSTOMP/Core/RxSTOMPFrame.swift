//
//  StompFrame.swift
//
//  Created by Pavel Shatalov on 27.02.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//

import Foundation

/*
 Here's STOMP protocol message packet structure
 It containes HEADERS and BODY
 HEADERS divided by \n, and messages by \0
 We're usen Set<> for constructing any STOMP message
*/

public enum RxSTOMPCommand: String {
    case connect = "STOMP"
    case disconnect = "DISCONNECT"
    case subscribe = "SUBSCRIBE"
    case unsubscribe = "UNSUBSCRIBE"
    case ping = "\n"
    case connected = "CONNECTED"
    case disconnected = "DISCONNECTED"
    case message = "MESSAGE"
    case error = "ERROR"
    case send = "SEND"
    case receipt = "RECEIPT"
    
    //MARK- failable init
    init(text: String) throws {
        guard let command = RxSTOMPCommand(rawValue: text) else {
            throw NSError(domain: "co.rxstomp.error", code: 1002, userInfo: [NSLocalizedDescriptionKey : "Received command is undefined"])
        }
        self = command
    }
}

// MARK: - Headers
public enum RxSTOMPHeader: Hashable {
    case host(host: String)
    case login(login: String)
    case passcode(passcode: String)
    case acceptVersion(version: String)
    case heartBeat(value: String)
    case destination(path: String)
    case destinationId(id: String)
    case custom(key: String, value: String)
    case receipt(receipId: String)
    case device_id(device_id: String)
    case version(version: String)
    case subscription(subId: String)
    case messageId(id: String)
    case contentLength(length: String)
    case message(message: String)
    case userName(name: String)
    case contentType(type: String)
    
    // MARK: - Public Properties
    var key: String {
        switch self {
        case .host:
            return "host"
        case .login:
            return "login"
        case .passcode:
            return "passcode"
        case .acceptVersion:
            return "accept-version"
        case .heartBeat:
            return "heart-beat"
        case .destination:
            return "destination"
        case .destinationId:
            return "id"
        case .custom(let key, _):
            return key
        case .version:
            return "version"
        case .subscription:
            return "subscription"
        case .messageId:
            return "message-id"
        case .contentLength:
            return "content-length"
        case .message:
            return "message"
        case .userName:
            return "user-name"
        case .contentType:
            return "content-type"
        case .receipt:
            return "receipt"
        case .device_id:
            return "device_id"
        }
    }
    
    var value: String {
        switch self {
        case .host(let host):
            return host
        case .login(let login):
            return login
        case .passcode(let passcode):
            return passcode
        case .acceptVersion(let version):
            return version
        case .heartBeat(let value):
            return value
        case .destination(let path):
            return path
        case .destinationId(let id):
            return id
        case .custom(_, let value):
            return value
        case .version(let version):
            return version
        case .subscription(let subId):
            return subId
        case .messageId(let id):
            return id
        case .contentLength(let length):
            return length
        case .message(let body):
            return body
        case .userName(let name):
            return name
        case .contentType(let type):
            return type
        case .receipt(let receiptId):
            return receiptId
        case .device_id(let device_id):
            return device_id
        }
    }
    
    var isMessage: Bool {
        switch self {
        case .message:
            return true
        default:
            return false
        }
    }
    
    var isDestination: Bool {
        switch self {
        case .destination:
            return true
        default:
            return false
        }
    }
    
    public var hashValue: Int {
        return key.hashValue ^ value.hashValue
    }
    
    // MARK: Designated Initializer
    init(key: String, value: String) {
        switch key {
        case "version":
            self = .version(version: value)
        case "subscription":
            self = .subscription(subId: value)
        case "message-id":
            self = .messageId(id: value)
        case "content-length":
            self = .contentLength(length: value)
        case "message":
            self = .message(message: value)
        case "destination":
            self = .destination(path: value)
        case "heart-beat":
            self = .heartBeat(value: value)
        case "user-name":
            self = .userName(name: value)
        case "content-type":
            self = .contentType(type: value)
        case "receipt":
            self = .receipt(receipId: value)
        case "device_id":
            self = .device_id(device_id: value)
        default:
            self = .custom(key: key, value: value)
        }
    }
    
    // MARK: - Equatable
    public static func ==(lhs: RxSTOMPHeader, rhs: RxSTOMPHeader) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Response Types
enum RxSTOMPResponseType: String {
    
    case Open = "o"
    case HeartBeat = "h"
    case Array = "a"
    case Message = "m"
    case Close = "c"
    
    // MARK: - Failable Initializer
    init(character: Character) throws {
        guard let type = RxSTOMPResponseType(rawValue: String(character)) else {
            throw NSError(domain: "co.rxstomp.error", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Received type is undefined."])
        }
        self = type
    }
}

// MARK: - Frame
public struct RxSTOMPFrame: CustomStringConvertible {
    
    // MARK: - Public Properties
    public var description: String {
        var string = command.rawValue + lineFeed
        for header in headers {
            string += header.key + ":" + header.value + lineFeed
        }
        if let body = self.body {
            string += lineFeed + body + nullChar
        } else {
            string += lineFeed + nullChar
        }
        
        return string
    }
    
    var message: String {
        if let header = headers.filter({ $0.isMessage }).first {
            return header.value
        } else {
            return ""
        }
    }
    
    var destination: String {
        if let header = headers.filter({ $0.isDestination }).first {
            return header.value
        } else {
            return ""
        }
    }
    
    // MARK: - Private Properties
    private let lineFeed = "\n"
    private let nullChar = "\0"
    private(set) var command: RxSTOMPCommand
    private(set) var headers: Set<RxSTOMPHeader>
    private(set) var body: String?
    
    // MARK: - Designated Initializer
    init(command: RxSTOMPCommand, headers: Set<RxSTOMPHeader> = [], body: String? = nil) {
        self.command = command
        self.headers = headers
        self.body = body
    }
    
    // MARK: - Failable Initializer
    init(text: String?) throws {
        //print("RECEIVED RAW STRING: \(text)")
        guard let incomingText = text, incomingText.characters.count != 0 else {
            throw NSError(domain: "co.rxstomp.error", code: 1002, userInfo: [NSLocalizedDescriptionKey : "Received frame is empty."])
        }
        
        let components = incomingText.components(separatedBy: "\n")
        let command =  incomingText == "\n" ? .ping : try RxSTOMPCommand(text: components.first!)
        
        var headers: Set<RxSTOMPHeader> = []
        var body = ""
        var isBody = false
        for index in 1 ..< components.count {
            let component = components[index]
            if isBody {
                body += component
                if body.hasSuffix("\0") {
                    body = body.replacingOccurrences(of: "\0", with: "")
                }
            } else {
                if component == "" {
                    isBody = true
                } else {
                    let parts = component.components(separatedBy: ":")
                    guard let key = parts.first, let value = parts.last else {
                        continue
                    }
                    let header = RxSTOMPHeader(key: key, value: value)
                    headers.insert(header)
                }
            }
        }
        
        self.init(command: command, headers: headers, body: body)
    }
}

