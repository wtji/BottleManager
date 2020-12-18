// Reference: https://ladvien.com/arduino-nano-33-bluetooth-low-energy-setup/
// Created by Owen Li

#include <ArduinoBLE.h>

const int ledPin1 = 22;
const int ledPin2 = 23;
const int ledPin3 = 24;
const int bottle1Pin = 5;
unsigned long int curr_time = 0;
unsigned long int old_time_phone = 0;
unsigned long int old_time_bottle_1 = 0;
int bottle_1_State = 0;
BLEService ledService("19b10000-e8f2-537e-4f6c-d104768a1214");

BLEByteCharacteristic switchCharacteristic("19b10000-e8f2-537e-4f6c-d104768a1334", BLERead | BLEWrite);
BLEByteCharacteristic bottle1statusCharacteristic("19b10000-e8f2-537e-4f6c-d104768a1333", BLERead | BLENotify);

BLEUnsignedLongCharacteristic dateCharacteristic("19b10000-e8f2-537e-4f6c-d104768a1314", BLERead);        //Characteristic for displaying time period since last BLE connection
BLEUnsignedLongCharacteristic bottle1Characteristic("19b10000-e8f2-537e-4f6c-d104768a1552", BLERead);     //Characteristic for displaying time period since last bottle 1 was used
BLEUnsignedLongCharacteristic runningtimeCharacteristic("19b10000-e8f2-537e-4f6c-d104768a0123", BLERead); //Characteristic for displaying time period since boot up.

void setup()
{

  Serial.begin(9600);
  while (!Serial)
    ; // Uncomment to wait for serial port to connect.

  // Set LED pin to output mode
  pinMode(22, OUTPUT);
  pinMode(23, OUTPUT);
  pinMode(24, OUTPUT);
  pinMode(bottle1Pin, INPUT);
  digitalWrite(ledPin1, HIGH); // red
  digitalWrite(ledPin2, HIGH); // green
  digitalWrite(ledPin3, HIGH); // blue

  // Begin initialization
  if (!BLE.begin())
  {
    Serial.println("Starting BLE failed!");
    digitalWrite(ledPin1, LOW);
    delay(1000);
    digitalWrite(ledPin1, HIGH);
    // Stop if BLE couldn't be initialized.
    while (1)
      ;
  }

  // Set advertised local name and service UUID:
  BLE.setLocalName("Smart Bottle");
  BLE.setAdvertisedService(ledService);

  // Add the characteristic to the service
  ledService.addCharacteristic(switchCharacteristic);
  ledService.addCharacteristic(bottle1statusCharacteristic);
  ledService.addCharacteristic(dateCharacteristic);
  ledService.addCharacteristic(bottle1Characteristic);
  ledService.addCharacteristic(runningtimeCharacteristic);

  // Add service
  BLE.addService(ledService);

  // Set the initial value for the characeristic:
  switchCharacteristic.writeValue(0);
  //bottle1statusCharacteristic.writeValue(0);
  dateCharacteristic.writeValue(0);
  bottle1Characteristic.writeValue(0);
  runningtimeCharacteristic.writeValue(0);

  // start advertising
  BLE.advertise();
  digitalWrite(ledPin2, LOW);
  delay(1000);
  digitalWrite(ledPin2, HIGH);
  Serial.println("BLE Control ready");
  bottle_1_State = digitalRead(bottle1Pin);
  bottle1statusCharacteristic.writeValue(bottle_1_State);
  Serial.print(bottle_1_State);
}

void loop()
{
  // Listen for BLE peripherals to connect:
  BLEDevice central = BLE.central();
  unsigned long int time, time2;
  update_running_time(runningtimeCharacteristic);

  // If a central is connected to peripheral:
  if (central)
  {
    Serial.print("Phone Connected to central: ");
    // Print the central's MAC address:
    Serial.println(central.address());
    if (old_time_phone == 0)
    { //for first connection
      time = 0;
      Serial.print(time);
      Serial.println(" seconds has elapsed since last bluetooth connection ");
      Serial.print(old_time_phone);
      Serial.println(" old time ");
      Serial.print(curr_time);
      Serial.println(" current time ");
      dateCharacteristic.writeValue(time);
    }
    else
    {
      //old_time_phone = curr_time;
      time = get_time_passed(old_time_phone);
      Serial.print(time);
      Serial.println(" seconds has elapsed since last bluetooth connection ");
      Serial.print(old_time_phone);
      Serial.println(" old time ");
      Serial.print(curr_time);
      Serial.println(" current time ");
      dateCharacteristic.writeValue(time);
    }

    // While the central is still connected to peripheral:
    while (central.connected())
    {
      update_running_time(runningtimeCharacteristic);
      bottle_1_State = digitalRead(bottle1Pin); //monitor connection to the bottle while BLE is connected

      if (bottle1statusCharacteristic.value() != bottle_1_State)
      { //if the status of the bottle changed, update the value
        bottle1statusCharacteristic.writeValue(bottle_1_State);
        if (bottle_1_State == 0)
        { //if bottle got disconnected, record time.
          if (old_time_bottle_1 == 0)
          { 
            update_running_time(runningtimeCharacteristic);
            time2 = get_time_passed(old_time_bottle_1);
            Serial.print(time2);
            Serial.println(" seconds has elapsed since last pill taken ");
            Serial.print(old_time_bottle_1);
            Serial.println(" old time ");
            Serial.print(old_time_bottle_1);
            Serial.println(" current time ");
            bottle1Characteristic.writeValue(time2);
          }
          else
          {
            update_running_time(runningtimeCharacteristic);
            time2 = get_time_passed(old_time_bottle_1);
            Serial.print(time2);
            Serial.println(" seconds has elapsed  since last pill taken ");
            Serial.print(old_time_bottle_1);
            Serial.println(" old time ");            
            Serial.print(old_time_bottle_1);
            Serial.println(" current time ");
            bottle1Characteristic.writeValue(time2);
          }
          old_time_bottle_1 = millis() * 0.001; //update the latest time when bottle got disconnected 
        }
        else{
          update_running_time(runningtimeCharacteristic);
        }
      }
      if (switchCharacteristic.written())
      {
        if (switchCharacteristic.value())
        { // Any value other than 0
          Serial.println("LED on");
          digitalWrite(ledPin1, LOW); // Will turn the Portenta LED on
        }
        else
        {
          Serial.println("LED off");
          digitalWrite(ledPin1, HIGH); // Will turn the Portenta LED off
        }
      }
    }

    // When the central disconnects, print it out:

    old_time_phone = millis() * 0.001; //get the time when connection ends
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
  }
  else //when no BLE connection has been made, monitor bottle status
  {
    bottle_1_State = digitalRead(bottle1Pin); 
    if (bottle1statusCharacteristic.value() != bottle_1_State)
      { //if the status of the bottle changed, update the value
        bottle1statusCharacteristic.writeValue(bottle_1_State);
        if (bottle_1_State == 0)
        { //if bottle got disconnected, record time.
          if (old_time_bottle_1 == 0)
          { 
            update_running_time(runningtimeCharacteristic);
            time2 = get_time_passed(old_time_bottle_1);
            Serial.print(time2);
            Serial.println(" seconds has elapsed since last pill taken ");
            Serial.print(old_time_bottle_1);
            Serial.println(" old time ");
            Serial.print(old_time_bottle_1);
            Serial.println(" current time ");
            bottle1Characteristic.writeValue(time2);
          }
          else
          {
            update_running_time(runningtimeCharacteristic);
            time2 = get_time_passed(old_time_bottle_1);
            Serial.print(time2);
            Serial.println(" seconds has elapsed  since last pill taken ");
            Serial.print(old_time_bottle_1);
            Serial.println(" old time ");            
            Serial.print(old_time_bottle_1);
            Serial.println(" current time ");
            bottle1Characteristic.writeValue(time2);
          }
          old_time_bottle_1 = millis() * 0.001; //update the latest time when bottle got disconnected 
        }
        else{
          update_running_time(runningtimeCharacteristic);
        }
      }
  }
}

unsigned long int get_time_passed(unsigned long int old_time)
{
  unsigned long int time;
  curr_time = millis() * 0.001;
  time = curr_time - old_time;
  return time;
}
void update_running_time(BLEUnsignedLongCharacteristic x)
{
  unsigned long int time;
  time = millis() * 0.001;
  x.writeValue(time);
}
