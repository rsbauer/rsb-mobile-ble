//
//  ContentView.swift
//  rsb-mobile-ble
//
//  Created by Astro on 6/23/24.
//

import SwiftUI
import Combine

// TODO?  https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities

struct ContentView<ViewModel>: View where ViewModel: SensorViewModel {
    @ObservedObject var model: ViewModel

    var body: some View {
        VStack {
            ForEach(model.sensed) { sensor in
                SensorView(model: sensor)
            }
        }
        .padding()
    }
}

struct SensorView<ViewModel>: View where ViewModel: BME280SensorModel {
    var model: ViewModel

    @State var elapseTime: String = "-"
    @State var lastSentTime: String = "-"

    private let dateFormat = DateFormatter()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Text("\(model.name)")
                .fontWeight(.bold)
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)

            HStack {
                GroupBox {
                    Text("F \(Image(systemName: "thermometer.medium"))")
                    Text("\(model.temperatureInF, specifier: "%.2f")")
                        .fixedSize()
                        .font(.largeTitle)
                        .frame(width: 100)
                        .frame(maxWidth: .infinity)
                }
                .backgroundStyle(temperatureColor(model.temperatureInF))

                GroupBox {
                    Text("% \(Image(systemName: "humidity.fill"))")
                    Text("\(model.humidityPercent, specifier: "%.2f")")
                        .fixedSize()
                        .font(.largeTitle)
                        .frame(width: 100)
                        .frame(maxWidth: .infinity)
                }
                .backgroundStyle(humidityColor(model.humidityPercent))
            }

            HStack {
                GroupBox {
                    Text("in \(Image(systemName: "gauge.with.dots.needle.67percent"))")
                    Text("\(model.pressureInHG, specifier: "%.2f")")
                        .fixedSize()
                        .font(.largeTitle)
                        .frame(width: 100)
                        .frame(maxWidth: .infinity)
                }

                GroupBox {
                    Text("\(self.elapseTime) \(Image(systemName: "iphone.and.arrow.forward"))")
                        .onReceive(timer) { time in
                            self.elapseTime = getElapsedTime(fromDate: model.lastUpdate, toDate: Date())
                            self.lastSentTime = getElapsedTime(fromDate: model.lastSent, toDate: Date())
                        }

                    Text("\(self.lastSentTime) \(Image(systemName: "square.and.arrow.up"))")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 30)
                }
            }
        }
        .padding()
    }

    func humidityColor(_ humidityPercent: Double) -> Color {
        if humidityPercent > 80 {
            return Color.blue
        }

        if humidityPercent < 45 {
            return Color.orange
        }

        return Color(.systemGray6)
    }

    func temperatureColor(_ temperature: Double) -> Color {
        if temperature > 80 {
            return Color.red
        }

        if temperature < 45 {
            return Color.blue
        }

        return Color(.systemGray6)
    }

    func formatDate(_ date: Date?) -> String {
        dateFormat.dateFormat = "yyyy-MM-dd hh:mm:ss a"
        guard let date else {
            return "No update"
        }
        return dateFormat.string(from: date)
    }

    func getElapsedTime(fromDate: Date?, toDate: Date?) -> String {
        let defaultValue = "-"

        guard let fromDate, let toDate else {
            return defaultValue
        }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad

        let localElapsedTime: TimeInterval = fromDate.timeIntervalSince(toDate)

        let elapsedString = formatter.string(from: localElapsedTime)
        return elapsedString ?? defaultValue
    }

}

#Preview {
    ContentView(model: MockSensorViewModel())
}
