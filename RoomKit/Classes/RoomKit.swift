//
//  RoomKit.swift
//  Nimble
//
//  Created by John Kotz on 2/2/18.
//

import Foundation

class RoomKit {
	private static var unProtConfig: RoomKit.Config!
	public static var config: RoomKit.Config {
		if self.unProtConfig == nil {
			fatalError("RoomKit: Config missing! You are required to have a configuration\n" +
				"Run:\nlet config = RoomKit.Config(dict: NSDictionary(contentsOfFile: filePath))\n" +
				"DALIapi.configure(config)\n" +
				"before you use it")
		}
		return unProtConfig!
	}
	
	static func configure(config: RoomKit.Config) {
		
	}
}
