# rsb-mobile-ble

A proof-of-concept app for communicating data over BLE for iOS and ESP32.

A little app which handles a BME280 sensor connected to an ESP32.  The ESP32 sends the data to this app for display and processing.  

The app can handle multiple sensors at the same time (as of this writing, 2 will work).  

SwiftUI is used and a little bit of the MVVM is used, although likely not optimal.  The goal was to wire Bluetooth BLE functionality and communicating BLE updates using Combine.  

### App Features:
* Wgeb foregrounded, app sends command to sensor device to provide updates every second
* When backgrounded, app sends command to sensor device to provide updates every couple minutes (to save battery)
* App handles background BLE message updates 
* UI uses SwiftUI and Combine
* App shows when last BLE and web service upload has taken place

### Screen Shots

<img src="https://raw.githubusercontent.com/rsbauer/rsb-mobile-ble/main/images/screenshot.PNG" width="300">

### Usage

## ESP32

Located in the ESP32 directories in this project, are two Arduino projects.  The full time project is meant for an ESP32 to be plugged into power full time.  The other project optimizes for battery operation.  

Configure the code for the ESP32 and deploy.  Connect the BME280 to the ESP32.  When powered on, it'll look for the rsb-mobile-ble app by broadcasting it's service.  The app will recognize this and ask for the ESP32 characteristics.  They will match and the two devices will establish communications.  

## iOS

The Xcode project is wired to communicate to devices running code from the ESP32 project directories.  Order the devices are started does not matter and when both are on and running, they should establish a connection and sensor data received.  At this time, the app strictly displays data and there's not much user interaction (as of this writing)


