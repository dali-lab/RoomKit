//
//  MapTrainer.swift
//  Nimble
//
//  Created by John Kotz on 2/5/18.
//

import Foundation
import CoreLocation

extension RoomKit {
	class Trainer {
		static var instance: RoomKit.Trainer!
		var trainingMap: Map?
		var locationManager = CLLocationManager()
		
		private init?() {
			if RoomKit.Trainer.instance != nil {
				return nil
			}
			RoomKit.Trainer.instance = self
		}
		
		func getInstance() -> Trainer {
			return Trainer() ?? RoomKit.Trainer.instance
		}
		
		func startTraining(map: RoomKit.Map) throws {
			if trainingMap != nil {
				throw error.AlreadyTrainingMap
			}
			trainingMap = map
			BeaconManager.getInstance().startingRangingMap(map: map)
		}
		
		func stopTraining() {
			trainingMap = nil
		}
	}
}
