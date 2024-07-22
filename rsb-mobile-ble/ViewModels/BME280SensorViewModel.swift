//
//  BME280SensorViewModel.swift
//  rsb-mobile-ble
//
//  Created by Astro on 6/29/24.
//

import Foundation
import Combine
import SwiftUI

class BME280SensorViewModel: SensorViewModel {
    @Published private(set) var bleStatus: BLEStatus = .unknown
    @Published private(set) var lastUpdate: Date?

    @Published private(set) var sensed = [BME280SensorModel]()

    // may be useful: https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html

    var bluetoothManager = BluetoothManager()
    var appStateNotificationService = AppStateNotificationService()

    private var cancellables: [AnyCancellable] = []

    init() {
        let cancellable: AnyCancellable! = appStateNotificationService.$appState.sink { [self] value in
            switch(value) {
            case .foreground:
                bluetoothManager.startup()
                bluetoothManager.setDelayTime(1000)        // delay in ms
            case .background:
                // send command to device to: disconnect and throttle notifications
//                bluetoothManager.shutdown()            // if want to shutdown BLE when app goes to sleep
                bluetoothManager.setDelayTime(-1)        // let BLE device sleep
                break
            }
        }

        cancellable.store(in: &cancellables)

        let responseCancellable = bluetoothManager.$bleResponse
            .receive(on: DispatchQueue.main)
            .sink { [self] sensorValue in
                // parse sesnorValue into components
                guard let sensorValue else { return }

                var sensor = BME280SensorModel()

                // if named not in array, add it, otherwise update it
                if let existingSensor = sensed.first(where: { model in
                    return model.name == sensorValue.name
                }) {

                    sensor = updateSensor(sensorValue: sensorValue, sensorToUpdate: existingSensor)
                } else {
                    // name doesn't exist so add a new item to the collection
                    let newSensor = BME280SensorModel()
                    newSensor.name = sensorValue.name     // data will be from RSBCar or RSBM (mobile)

                    sensor = updateSensor(sensorValue: sensorValue, sensorToUpdate: newSensor)
                    sensed.append(sensor)
               }

                sendToHome(sensor)
            }

        responseCancellable.store(in: &cancellables)

        let bleStatusCancellable = bluetoothManager.$bleStatus
            .receive(on: DispatchQueue.main)
            .sink { [self] status in
                bleStatus = status
            }
        bleStatusCancellable.store(in: &cancellables)
    }

    func updateSensor(sensorValue: BLEResponse, sensorToUpdate: BME280SensorModel) -> BME280SensorModel {
        sensorToUpdate.setTemperatureInF(sensorValue.temperatureInF)
        sensorToUpdate.setHumidity(sensorValue.humidityPercent)
        sensorToUpdate.setPressure(sensorValue.pressureInHG)

        sensorToUpdate.lastUpdate = sensorValue.lastUpdate

        return sensorToUpdate
    }

    func writeToBLE() {
        bluetoothManager.writeToPeripheral(string: "YO YO YO")
    }

    func sendToHome(_ response: BME280SensorModel) {
        // guard got a little funky here - opted for if let
        if Date.now.timeIntervalSince1970 < (response.lastSent.timeIntervalSince1970 + 30) {
            return
        }

        print("Sending to rsb0")
        var name = "rsb-mobile"
        switch response.name {
        case "RSBM":
            name = "rsb-mobile"
        case "RSBCar":
            name = "rsb-car"
        default:
            name = "unknown"
        }

        let json: [String: Any] = [
            "identity": name,
            "temperature": "\(response.temperatureInF)",
            "humidity": "\(response.humidityPercent)",
            "pressure": "\(response.pressureInHG)",
        ]

        Network().POST(url: "<your url here>", json: json)

        response.lastSent = Date()
    }
}

