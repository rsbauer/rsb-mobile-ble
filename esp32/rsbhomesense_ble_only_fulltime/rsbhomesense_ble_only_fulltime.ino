#include <Wire.h>
#include <SPI.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME280.h>
#include <Adafruit_NeoPixel.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Preferences.h>    // https://randomnerdtutorials.com/esp32-save-data-permanently-preferences/

#define BME_SCK 19
#define BME_MISO 12
#define BME_MOSI 22
#define BME_CS 10

#define SEALEVELPRESSURE_HPA (1013.25)

// button and led state
const int buttonPin = 0;    // boot button
int buttonState = 0;        // button state
int ledState = 0;
String oldTXValue = "";

Preferences preferences;
const char* appNameForPreferences = "homesense";
const char* delayTimeKey = "delayTime";

// BLE
BLEServer *pServer = NULL;
BLECharacteristic *pTxCharacteristic;
bool deviceConnected = false;
bool oldDeviceConnected = false;
#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"  // UART service UUID
#define CHARACTERISTIC_UUID_RX "8b903a4b-f398-4850-aa3c-bc09ac1ab5dc"
#define CHARACTERISTIC_UUID_TX "cb1c94a1-221a-4c0e-8dc5-33cc44a677f2"


// log service
const char* identity = "rsb-mobile";   // values: bedroom, balcony, livingroom

Adafruit_BME280 bme; // I2C

long delayTime = 1000;
unsigned long bleRetries = 0;
long default_sleep_in_minutes = 60 * 2;   // 2 minutes

#if defined(PIN_NEOPIXEL)
  Adafruit_NeoPixel pixel(1, PIN_NEOPIXEL, NEO_GRB + NEO_KHZ800);
#endif

// BLE classes
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
  };

  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
  }
};

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String rxValue = pCharacteristic->getValue();

    if (rxValue.length() > 0) {
      Serial.println("*********");
      Serial.print("Received Value: ");
      for (int i = 0; i < rxValue.length(); i++) {
        Serial.print(rxValue[i]);
      }

      Serial.println();
      Serial.println("*********");

      // process
      if(rxValue.length() > 3 && rxValue[0] == 'd') {
        // get value
        String delayValueStr = rxValue.substring(2, rxValue.length());
        delayTime = delayValueStr.toInt();
        preferences.begin(appNameForPreferences, false);   // false = read/write
        preferences.putLong(delayTimeKey, delayTime);
        preferences.end();
      }
    }
  }
};

// END BLE classes


void setup() {
  Serial.begin(115200);
  while (!Serial);   // time to get serial running
  Serial.println(F("rsbhomesense"));

  preferences.begin(appNameForPreferences, true);  // read only mode
  delayTime = preferences.getLong(delayTimeKey, delayTime);
  preferences.end();

  LEDon(0xFFBF00);    // amber

  // during setup, could we monitor for bluetooth??
  startBLE();

  unsigned status;

  // default settings
  Wire1.setPins(SDA1, SCL1);
  status = bme.begin(BME280_ADDRESS, &Wire1); // defaults to WIRE, but need WIRE1
  // status = bme.begin(0x77, &WIRE1);
  // You can also pass in a Wire library object like &Wire2
  // status = bme.begin(0x76, &Wire2)
  if (!status) {
    Serial.println("Could not find a valid BME280 sensor, check wiring, address, sensor ID!");
    Serial.print("SensorID was: 0x"); Serial.println(bme.sensorID(), 16);
    Serial.print("        ID of 0xFF probably means a bad address, a BMP 180 or BMP 085\n");
    Serial.print("   ID of 0x56-0x58 represents a BMP 280,\n");
    Serial.print("        ID of 0x60 represents a BME 280.\n");
    Serial.print("        ID of 0x61 represents a BME 680.\n");
    while (1) delay(10);
  }

  // OneWire
  //    sensors.begin();

  // power management and setup
  pinMode(buttonPin, INPUT);      // init button to be input
  digitalWrite(buttonPin, HIGH);  // needs pull up resistor to be enabled

  // Turn on any internal power switches for TFT, NeoPixels, I2C, etc!
  enableInternalPower();

  ledState = 0;
  // end power management and setup

  Serial.println("-- Starting Sensing --");

  Serial.println();
}


void loop() {
  // ISSUE: loop() requires device to be connected to wifi :-(  <-- should find a way to scan for wifi AND BLE
  // LEDon(0x228B22);    // green
  float tempF = (bme.readTemperature() * 9.0F / 5.0F) + 32.0F;
  float pressureInHG = bme.readPressure() / 100.0F * 0.030F;
  float altitudeFt = bme.readAltitude(SEALEVELPRESSURE_HPA) * 3.28084F;
  float humidity = bme.readHumidity();

  // BLE
  if (deviceConnected) {
    LEDon(0x0000FF);    // blue
    String txValue = String(tempF);
    txValue += ",";
    txValue += String(humidity);
    txValue += ",";
    txValue += String(pressureInHG);

    // only send if the value changed    
    if(txValue != oldTXValue) {
      pTxCharacteristic->setValue(txValue);
      pTxCharacteristic->notify();
      oldTXValue = txValue;
    }
    // delay(5000);  // bluetooth stack will go into congestion, if too many packets are sent, in MS
  }

  printValues(tempF, pressureInHG, altitudeFt, humidity);

  Serial.print("Delay time: ");
  delay(1000);
}

void printValues(float tempF, float pressureInHG, float altitudeFt, float humidity) {
  //    sensors.requestTemperatures();
  //    float tempFOneWire = sensors.getTempFByIndex(0);


  Serial.print("Temperature = ");
  Serial.print(tempF);
  //    Serial.print(" | ");
  //    Serial.print(tempFOneWire);
  Serial.println(" °F");

  Serial.print("Pressure = ");

  Serial.print(pressureInHG);
  Serial.println(" inHg");

  Serial.print("Approx. Altitude = ");
  Serial.print(altitudeFt);
  Serial.println(" ft");

  Serial.print("Humidity = ");
  Serial.print(humidity);
  Serial.println(" %");

  Serial.println();
}

// END temperature functions

void doShutdown() {
    shutdown(1000000 * default_sleep_in_minutes);   // 2 minutes
    // shutdown(1000000 * 30);   // 30s
}

void shutdown(uint64_t time_in_us) {
  LEDoff();
  disableInternalPower();
  // esp_sleep_enable_timer_wakeup(1000000); // 1 sec
  // esp_light_sleep_start();
  // we'll wake from light sleep here

  // wake up 1 second later and then go into deep sleep
  esp_sleep_enable_timer_wakeup(time_in_us); // 1 sec
  esp_deep_sleep_start(); 
}

void LEDon(uint32_t color) {
#if defined(PIN_NEOPIXEL)
  pixel.begin(); // INITIALIZE NeoPixel
  pixel.setBrightness(20); // not so bright
  pixel.setPixelColor(0, color);
  pixel.show();
#endif
}

void LEDoff() {
#if defined(PIN_NEOPIXEL)
  pixel.setPixelColor(0, 0x0);
  pixel.show();
#endif
}

void enableInternalPower() {
#if defined(NEOPIXEL_POWER)
  pinMode(NEOPIXEL_POWER, OUTPUT);
  digitalWrite(NEOPIXEL_POWER, HIGH);
#endif

#if defined(NEOPIXEL_I2C_POWER)
  pinMode(NEOPIXEL_I2C_POWER, OUTPUT);
  digitalWrite(NEOPIXEL_I2C_POWER, HIGH);
#endif

#if defined(ARDUINO_ADAFRUIT_FEATHER_ESP32S2)
  // turn on the I2C power by setting pin to opposite of 'rest state'
  pinMode(PIN_I2C_POWER, INPUT);
  delay(1);
  bool polarity = digitalRead(PIN_I2C_POWER);
  pinMode(PIN_I2C_POWER, OUTPUT);
  digitalWrite(PIN_I2C_POWER, !polarity);
  pinMode(NEOPIXEL_POWER, OUTPUT);
  digitalWrite(NEOPIXEL_POWER, HIGH);
#endif
}

void disableInternalPower() {
#if defined(NEOPIXEL_POWER)
  pinMode(NEOPIXEL_POWER, OUTPUT);
  digitalWrite(NEOPIXEL_POWER, LOW);
#endif

#if defined(NEOPIXEL_I2C_POWER)
  pinMode(NEOPIXEL_I2C_POWER, OUTPUT);
  digitalWrite(NEOPIXEL_I2C_POWER, LOW);
#endif

#if defined(ARDUINO_ADAFRUIT_FEATHER_ESP32S2)
  // turn on the I2C power by setting pin to rest state (off)
  pinMode(PIN_I2C_POWER, INPUT);
  pinMode(NEOPIXEL_POWER, OUTPUT);
  digitalWrite(NEOPIXEL_POWER, LOW);
#endif
}

// BLE functions
void startBLE() {
  // Create the BLE Device
  BLEDevice::init("RSBCar");

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic
  pTxCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_TX, BLECharacteristic::PROPERTY_NOTIFY);

  pTxCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_RX, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);

  pRxCharacteristic->setCallbacks(new MyCallbacks());

  // Start the service
  pService->start();

  // Start advertising
  pServer->getAdvertising()->addServiceUUID(pService->getUUID());
  pServer->getAdvertising()->start();
  Serial.println("Waiting a client connection to notify...");
}
