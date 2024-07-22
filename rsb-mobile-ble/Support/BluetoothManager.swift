//
//  BluetoothManager.swift
//  rsb-mobile-ble
//
//  Created by Astro on 6/23/24.
//

import Foundation
import CoreBluetooth
import Combine
import UIKit

struct BLEResponse {
    var name: String

    var temperatureInF: Double
    var humidityPercent: Double
    var pressureInHG: Double
    var lastUpdate = Date()

    func debug() -> String {
        return "\(temperatureInF) \(humidityPercent) \(pressureInHG)"
    }
}

enum BLEStatus {
    case disconnected
    case scanning
    case connected
    case connecting
    case disconnecting
    case unknown
}

class BluetoothManager {
    var centralManager: CBCentralManager
    private let restoreIDKey = "rsb-mobile-ble"
    private var centralState: AnyCancellable? = nil
    private var peripheral: AnyCancellable? = nil
    private var receivedValue: AnyCancellable? = nil

    private var centralManagerDelegate = MobileBLECentralManager()
    private var peripheralDelegate = PeripheralManager()
    private var peripheralList: [CBPeripheral] = []

    @Published var bleResponse: BLEResponse?
    @Published var bleStatus: BLEStatus = .unknown

    init() {
        self.centralManager = CBCentralManager(delegate: self.centralManagerDelegate, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: restoreIDKey])

        centralState = centralManagerDelegate.$centralState
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [self] value in
                if value == .poweredOn {
                    startScanning()
                }
            })

        peripheral = centralManagerDelegate.$peripheral
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [self] value in
                centralManager.stopScan()
                guard let value else { return }
                value.delegate = peripheralDelegate
                connectTo(peripheral: value)
           })

        receivedValue = peripheralDelegate.$received
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                guard let value else { return }
                self?.bleResponse = value
            })
    }

    func startScanning() {
        print("Scanning...")
        centralManager.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
    }

    func connectTo(peripheral: CBPeripheral) {
        peripheralList.append(peripheral)
        centralManager.connect(peripheral, options: nil)
        bleStatus = .connected
    }

    func startup() {
        startScanning()
    }

    func shutdown() {
        bleStatus = .disconnecting
        centralManager.stopScan()
        for peripheral in peripheralList {
            centralManager.cancelPeripheralConnection(peripheral)
        }

        peripheralList.removeAll()
        bleStatus = .disconnected
    }

    func writeToPeripheral(string: String) {
        guard let peripheral = peripheralList.first else { return }
        peripheralDelegate.writeValue(to: peripheral, string: string)
    }

    func setDelayTime(_ delay: Int) {
        writeToPeripheral(string: "d:\(delay)")
        peripheralDelegate.setDelayTime(delay)
    }
}
