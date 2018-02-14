//
//  RoomKitDelegate.swift
//  Nimble
//
//  Created by John Kotz on 2/5/18.
//

import Foundation

protocol RoomKitDelegate {
	func enteredMappedRegion(map: RoomKit.Map)
	func determined(room: String, on map: RoomKit.Map)
	func exitedMappedRegion(map: RoomKit.Map)
}
