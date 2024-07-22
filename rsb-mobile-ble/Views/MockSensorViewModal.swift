//
//  MockSensorViewModal.swift
//  rsb-mobile-ble
//
//  Created by Astro on 6/29/24.
//

import Combine
import Foundation

class MockSensorViewModel: SensorViewModel {
    private(set) var name: String = MockSensorViewModel.randomName()
    private(set) var bleStatus: BLEStatus = .disconnected
    private(set) var lastUpdate: Date? = Date()
    private(set) var lastSent: Date? = Date()
    @Published private(set) var sensed = [BME280SensorModel]()

    private var cancellable: Cancellable?
    let queue = DispatchQueue.main

    init() {
        let name = MockSensorViewModel.randomName()

        cancellable = queue.schedule(after: queue.now, interval: .seconds(1), { [weak self] in
            guard let self else {
                return
            }

            // if named not in array, add it, otherwise update it
            if let existingSensor = sensed.first(where: { model in
                return model.name == name
            }) {
                self.populateSensor(sensor: existingSensor)
            } else {
                // name doesn't exist so add a new item to the collection
                let newSensor = BME280SensorModel()
                
                newSensor.name = name
                self.populateSensor(sensor: newSensor)
                sensed.append(newSensor)
           }
        })
    }

    func populateSensor(sensor: BME280SensorModel) {
        sensor.setTemperatureInF(Double(Double(MockSensorViewModel.randomNumber(from: -1000, to: 12000)) / 100))
        sensor.setHumidity(Double(Double(MockSensorViewModel.randomNumber(from: 0, to: 10000)) / 100))
        sensor.setPressure(Double(Double(MockSensorViewModel.randomNumber(from: 2000, to: 4000)) / 100))
        sensor.lastUpdate = Date()
    }

    func writeToBLE() {
        print("Write to BLE")
    }

    static func randomName(length: Int = 5) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""

        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }

        return randomString
    }

    static func randomNumber(from min: Int, to max: Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }

}
