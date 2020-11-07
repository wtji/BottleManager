# BottleManager
This is a course project of ECE M202A: Embedded System. The authors are Owen Li and Weiting Ji.

Youtube link to the demo: 

## Project Introduction
Nowadays, medicine and nutrition supplements are becoming an irreplaceable part of our lives. It is crucial for us to consume the designated dose at the designated time. For example, some medications are best if taken before the meal, while some are best if taken after, and some should be taken before going to bed. However, unknowns may happen, and people could miss the scheduled time to take the pills. Elder people might miss their medication due to amnesia. Adults may lose their track of medication by daily work. Many companies have developed apps or devices that could track users’ daily intake. But those types of devices usually cost a lot of money. Users also need to purchase multiple devices if taking various medications. So is it possible for us to design a more affordable and accessible solution? 

The objective of this project is to build a system using the small and cheap Arduino Nano 33 BLE Sense that can detect different contexts in which the user fails to take the medical pills and set up context-based alarms to inform the user. We want to separate the board and the bottle to maintain the maximum usability of the bottle. Additionally, we will develop an app that gives the alarm and allows the user to interact with the system. Moreover, the context the user fails to take the medication we are dealing with in this project is whether the user is busy doing other things or he just totally forgot to take; the context of when to take the medication is that the user should take the pills after the meal. In the future, more contexts will be analyzed and researched to reach the full context-based characteristics of the alarm system.

## Brief Timeline
* By 11/6 Literature search, purchase of material
* By 11/13 Design of alarm system, testing of Arduino
* By 11/25 Design of interative app, training of AI (if any)
* By 12/6 Validation testing, report and video making

## Analysis of Literature
### Bluetooth LE Connection
Since our system consists of the Arduino part and the smartphone application part, the method of connection between them has become a crucial point of our project. In this project, we are using the Arduino Nano 33 BLE Sense in our embedded system, so it is certain that we are going to use bluetooth low energy (BLE) connection to send and receive data. The most significant difference between conventional bluetooth and BLE is that BLE does not require one-to-one connection. In addition, BLE introduces much less power supply than bluetooth, which is good for long term monitoring using only a button cell battery. Take a look at the following figure that describes the role of devices in BLE connection.

<p align="center">
  <img src="https://www.arduino.cc/en/uploads/Reference/ble-bulletin-board-model.png" width="500" align="center"/>
</p>

The BLE connection is like a bulletin board, where the peripheral device provides services and characteristics and the central devices act as clients of services. In our case, the Arduino board is the peripheral device which monitors the status of the medicine bottle and sends out service with a UUID that contains the status; the device installed with the monitor app is the central device which accesses the service using its UUID and reads the characteristics from or writes the characteristics to the Arduino board. 

The Arduino BLE library is very powerful and integrated with the classes and methods for the service part. For use BLE in Arduino, we just need to include the library
```
#include<ArduinoBLE.h>
```
To start a BLE connection, we have the following code
```
if (!BLE.begin()){
    Serial.println("starting BLE failed!");
    while (1);
}
```
To detect whether the central device is connected, we have to first create a central device object and then do the detection
```
// create a central device object
BLEDevice central = BLE.central();

if (central) {
    while (central.connected()) {
	// put the main activity here
    }
}
```
As for sending or receiving data, ```Serial.print()``` and ```Serial.read()``` is enough for the BLE connection. Things are a little bit complicated at the central device side. We take the application based on Android as an example. In the Android Manifest file, we have to get the permission of using BLE connection with the following line
```
<uses-feature android:name="android.hardware.bluetooth_le" android:required="true"/>
```
The classes required for using BLE are as follows
```
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.*;
import java.util.UUID;
```
The method of onCreate, onScanResult, etc. will largely depend on the detailed deliverables so it is unnecessary to discuss it in this section. 
