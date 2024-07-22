//
//  BME280SensorModel.swift
//  rsb-mobile-ble
//
//  Created by Astro on 7/20/24.
//

import Foundation

class BME280SensorModel: Identifiable {
    @Published private(set) var temperatureInF: Double = 0
    @Published private(set) var humidityPercent: Double = 0
    @Published private(set) var pressureInHG: Double = 0

    @Published var name: String = "unknown"
    @Published var lastUpdate = Date()
    @Published var lastSent = Date()

    @Published private(set) var temperatureLow: Double = 99999
    @Published private(set) var temperatureHigh: Double = -99999
    @Published private(set) var humidityLow: Double = 99999
    @Published private(set) var humidityHigh: Double = -99999
    @Published private(set) var pressureLow: Double = 99999
    @Published private(set) var pressureHigh: Double = -99999

    public func setTemperatureInF(_ value: Double) {
        temperatureInF = value

        if value < temperatureLow {
            temperatureLow = value
        }

        if value > temperatureHigh {
            temperatureHigh = value
        }
    }

    public func setHumidity(_ value: Double) {
        humidityPercent = value

        if value < humidityLow {
            humidityLow = value
        }

        if value > humidityHigh {
            humidityHigh = value
        }
    }

    public func setPressure(_ value: Double) {
        pressureInHG = value

        if value < pressureLow {
            pressureLow = value
        }

        if value > pressureHigh {
            pressureHigh = value
        }
    }
}
