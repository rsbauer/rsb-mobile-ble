//
//  CBUUIDs.swift
//  rsb-mobile-ble
//
//  Created by Astro on 6/23/24.
//

import Foundation
import CoreBluetooth

struct CBUUIDs {
    static let kBLEService_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
    static let kBLE_Characteristic_uuid_tx = "cb1c94a1-221a-4c0e-8dc5-33cc44a677f2" // "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
    static let kBLE_Characteristic_uuid_rx = "8b903a4b-f398-4850-aa3c-bc09ac1ab5dc" // "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

    static let BLEService_UUID = CBUUID(string: kBLEService_UUID)
    static let BLE_Characteristic_uuid_tx = CBUUID(string: kBLE_Characteristic_uuid_tx)
    static let BLE_Characteristic_uuid_rx = CBUUID(string: kBLE_Characteristic_uuid_rx)
}
