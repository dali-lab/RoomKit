//
//  Error.swift
//  Nimble
//
//  Created by John Kotz on 2/2/18.
//

import Foundation

extension RoomKit {
	public enum error: Error {
		case ConfigValidationFailed(reason: String)
		case FailedToSerializeData
		case ActionFailed
		case AlreadyTrainingMap
	}
}
