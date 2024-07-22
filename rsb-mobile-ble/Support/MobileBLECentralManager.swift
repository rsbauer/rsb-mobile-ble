//
//  MobileBLECentralManager.swift
//  rsb-mobile-ble
//
//  Created by Astro on 6/23/24.
//

import Foundation
import CoreBluetooth
import Combine

class MobileBLECentralManager: NSObject, CBCentralManagerDelegate {
    @Published var centralState: CBManagerState = .unknown
    @Published var peripheral: CBPeripheral?

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        switch central.state {
        case .poweredOff:
            print("Is powered off")
        case .poweredOn:
            print("Is powered on")
        case .unsupported:
            print("Is unsupported")
        case .unauthorized:
            print("Is unauthorized")
        case .unknown:
            print("Is unknown")
        case .resetting:
            print("Resetting")
        @unknown default:
            print("Error - unknown state: \(central.state)")
        }

        centralState = central.state
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Peripheral discovered: \(peripheral)")
        print("Peripheral name: \(peripheral.name ?? "unknown")")
        print("Peripheral data: \(advertisementData)")

        self.peripheral = peripheral
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // from: https://www.splinter.com.au/2019/06/06/bluetooth-sample-code/
        let peripherals: [CBPeripheral] = dict[
            CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []

        if peripherals.count > 1 {
            print("Warning: willRestoreState called with >1 connection")
        }

        // What should we be doing here?  Restoring peripheral state
        // capture the first peripheral
        // set it to self, which will trigger it getting its delegate set
        // then discover services
        // https://stackoverflow.com/questions/37796780/corebluetooth-willrestorestate-what-exactly-should-be-done-there
        if let peripheral = peripherals.first {
            self.peripheral = peripheral
            peripheral.discoverServices([CBUUIDs.BLEService_UUID])
        }


    }
}
