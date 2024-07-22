//
//  PeripheralManager.swift
//  rsb-mobile-ble
//
//  Created by Astro on 6/23/24.
//

import Foundation
import CoreBluetooth

class PeripheralManager: NSObject, CBPeripheralDelegate, CBPeripheralManagerDelegate {
    @Published var tx: CBCharacteristic?
    @Published var rx: CBCharacteristic?
    @Published var received: BLEResponse?

    private(set) var delayTime = 1000

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        print("** ** **")

        if error != nil {
            print("Error discovering services: \(error?.localizedDescription ?? "unknown error")")
        }

        guard let services = peripheral.services else {
            return
        }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }

        print("Discovered services: \(services)")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard let characteristics = service.characteristics else {
            return
        }

        print("Found \(characteristics.count) characteristics")

        for characteristic in characteristics {
            if characteristic.uuid == CBUUIDs.BLE_Characteristic_uuid_tx {
                tx = characteristic
                guard let tx = tx else {
                    return
                }
    
                peripheral.setNotifyValue(true, for: tx)
//                peripheral.readValue(for: characteristic)

                print("TX Characteristic: \(tx.uuid.description)")
            }

            if characteristic.uuid == CBUUIDs.BLE_Characteristic_uuid_rx {
                rx = characteristic
                print("RX Characteristic: \(rx?.uuid.description ?? "unknown")")
            }
        }

        // needed to set the device to fall back a sleep or stay awake
        writeValue(to: peripheral, string: "d:\(delayTime)")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {

        guard let characteristicValue = characteristic.value, let ASCIIString = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue) else {
            return
        }

        received = processReceivedValue(ASCIIString: ASCIIString, name: peripheral.name ?? "unknown")       // name = RSBM <-- mobile, RSBCar, 
        print("Received: \(received?.debug() ?? "unknown")")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard let characteristicValue = characteristic.value, let ASCIIString = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue) else {
            print("Error: \(error?.localizedDescription ?? "unknown error")")
            return
        }

        received = processReceivedValue(ASCIIString: ASCIIString, name: peripheral.name ?? "unknown")
        print("Received: \(received?.debug() ?? "unknown")")
    }

    func processReceivedValue(ASCIIString: NSString, name: String) -> BLEResponse {
        let sensorValue = ASCIIString as String

        let parts = sensorValue.components(separatedBy: ",")
        guard parts.count >= 3 else { return BLEResponse(name: "none", temperatureInF: 0, humidityPercent: 0, pressureInHG: 0) }

        let temperatureInF = Double(parts[0]) ?? 0
        let humidityPercent = Double(parts[1]) ?? 0
        let pressureInHG = Double(parts[2]) ?? 0

        return BLEResponse(name: name, temperatureInF: temperatureInF, humidityPercent: humidityPercent, pressureInHG: pressureInHG)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("Received write request")
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Peripheral Is Powered On.")
        case .unsupported:
            print("Peripheral Is Unsupported.")
        case .unauthorized:
        print("Peripheral Is Unauthorized.")
        case .unknown:
            print("Peripheral Unknown")
        case .resetting:
            print("Peripheral Resetting")
        case .poweredOff:
          print("Peripheral Is Powered Off.")
        @unknown default:
          print("Error")
        }
    }

    func writeValue(to peripheral: CBPeripheral, string: String) {
        let value = (string as NSString).data(using: String.Encoding.utf8.rawValue)
        guard let value, let rx else { return }
        peripheral.writeValue(value, for: rx, type: CBCharacteristicWriteType.withResponse)
    }

    func setDelayTime(_ delay: Int) {
        delayTime = delay
    }

}
