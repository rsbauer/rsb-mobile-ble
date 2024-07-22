//
//  rsb_mobile_bleApp.swift
//  rsb-mobile-ble
//
//  Created by Astro on 6/23/24.
//

import SwiftUI
import CoreBluetooth
import Combine

// based on https://learn.adafruit.com/build-a-bluetooth-app-using-swift-5?view=all

@main
struct rsb_mobile_bleApp: App {
    private let viewModel = BME280SensorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: viewModel)
        }
    }
}

