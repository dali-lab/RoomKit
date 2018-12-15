//
//  Error.swift
//  Nimble
//
//  Created by John Kotz on 2/2/18.
//

import Foundation

extension RoomKit {
	public enum error: Error {
        case AdminKeyRequired
        case FailedToConnect
		case ConfigValidationFailed(reason: String)
		case FailedToSerializeData
		case ActionFailed
		case AlreadyTrainingMap
		case UnknownError
	}
}
