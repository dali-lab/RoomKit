//
//  Room.swift
//  EmitterKit
//
//  Created by John Kotz on 12/14/18.
//

import Foundation
import SwiftyJSON

extension RoomKit {
    public class Room: Hashable {
        public var hashValue: Int { return name.hashValue }
        public let name: String
        public let percentTrained: Double
        
        internal init(name: String, percentTrained: Double) {
            self.name = name
            self.percentTrained = percentTrained
        }
        
        internal init?(json: JSON) {
            guard let dict = json.dictionary, let name = dict["name"]?.string, let percentTrained = dict["percent_trained"]?.number else {
                return nil
            }
            self.name = name
            self.percentTrained = percentTrained.doubleValue
        }
        
        public static func == (lhs: RoomKit.Room, rhs: RoomKit.Room) -> Bool {
            return lhs.name == rhs.name
        }
        
        
    }
}
