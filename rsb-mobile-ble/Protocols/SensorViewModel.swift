//
//  SensorViewModel.swift
//  rsb-mobile-ble
//
//  Created by Astro on 6/29/24.
//

import Foundation

protocol SensorViewModel: ObservableObject {
    var sensed: [BME280SensorModel] { get }
    var bleStatus: BLEStatus { get }

    func writeToBLE()
}
