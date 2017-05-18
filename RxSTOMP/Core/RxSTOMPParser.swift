//
//  StompParser.swift
//
//  Created by Pavel Shatalov on 28.03.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//

import Foundation

/*
This is very simple STOMP protocol message parser
It accumulates data, until end of each message
For future optimization need to consider using data offset
*/
public class RxSTOMPParser {
    
    private var readData = Data()
    public func parse(data: Data) -> [RxSTOMPFrame] {
        self.readData.append(data)
        var frames = [RxSTOMPFrame]()
        let string = String(data: readData, encoding: .utf8)
        guard let commands = string?.components(separatedBy: "\0") else { return frames }
        print("\n****** RAW DATA: \(commands)\n **********")
        if commands.count == 1 && commands.first! != "\n" {
            return frames
        } else {
            for command in commands {
                do {
                    var msg = command.components(separatedBy: "\n")
                    while ((msg.first == "")) {
                        msg.remove(at: 0)
                    }
                    let filteredCommand = msg.joined(separator: "\n")
                    if filteredCommand.isEmpty { continue }
                    let frame = try RxSTOMPFrame(text: filteredCommand)
                    frames.append(frame)
                } catch {
                    print("ERROR PARSING COMMAND: \(command), \(error)")
                    self.readData.removeAll()
                }
            }
        }
        self.readData.removeAll()
        return frames
    }
}
