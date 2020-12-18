//
//  ViewController.swift
//  BottleManager
//
//  Created by Weiting Ji on 11/19/20.
//  Copyright © 2020 ucla. All rights reserved.
//
//  The framework of this alert app is based on the reminder app project
//  created by IOSAcademy https://github.com/AfrazCodes/SimpleReminders with modification
//  in notification trigger algorithm and with extension in Bluetooth Low Energy functionality

import UIKit
import UserNotifications
import CoreBluetooth

// UUID of serivce
let Alert_Service_UUID = CBUUID(string: "19b10000-e8f2-537e-4f6c-d104768a1214")
// UUID of bottle connection characteristic
let Mag_Connection_Status_UUID = CBUUID(string: "19b10000-e8f2-537e-4f6c-d104768a1333")
// UUID of LED on/off characteristic
let LED_UUID = CBUUID(string: "19b10000-e8f2-537e-4f6c-d104768a1334")


var BLE_Is_Connected_Flag = false;
var Bottle_Is_Connected_Flag = false;


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager?
    var peripheralAlert: CBPeripheral?
    var onOffCharateristic: CBCharacteristic?
    var pillNameStorage: String = ""
    var timeToTakeStorage: Date = Date()
    
    @IBOutlet var table: UITableView!
    
    @IBOutlet weak var ledOnOff: UIBarButtonItem!
    
    var model = [Reminder]()

    override func viewDidLoad() {
        super.viewDidLoad()
        table.delegate = self
        table.dataSource = self
    }
    
    @IBAction func didTapAdd() {
        // show the view controller containing add instruction
        guard let viewCtrl = storyboard?.instantiateViewController(identifier: "Add") as? AddViewController else {
            return
        }
        
        viewCtrl.title = "New Medication"
        viewCtrl.saveComplete = {pillName, timeToTake in
            DispatchQueue.main.async {
                self.navigationController?.popToRootViewController(animated: true)
                let new = Reminder(title: pillName, time: timeToTake, identifier: "id_\(pillName)")
                self.model.append(new)
                self.table.reloadData()
                self.timeToTakeStorage = timeToTake
                self.pillNameStorage = pillName
                
                self.scheduleAlert(pillName: pillName, timeToTake: timeToTake, message: "It's time to take your medicine!")
                
                self.centralManager = CBCentralManager(delegate: self, queue: nil)
            }
        }
        navigationController?.pushViewController(viewCtrl, animated: true)
    }

    @IBAction func didTapTest() {
        // fire test notification
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: {success, error in
            if success {
                // schedule test
                self.scheduleTest()
            } else if error != nil {
                print("error occured")
            }
        })
    }
    
    func scheduleTest() {
        // create content of the notification
        let content = UNMutableNotificationContent()
        content.title = "Hello"
        content.sound = .default
        content.body = "This is a notification"
        
        // set the triggering time (after 10 seconds of tapping the test button)
        let targetDate = Date().addingTimeInterval(10)
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute, .second], from: targetDate), repeats: true)
        
        // request the UNNotificationCenter to send the notification with "content" at "trigger" time
        let request = UNNotificationRequest(identifier: "some_id", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: {error in
            if error != nil {
                print("something is wrong")
            }
        })
    }
    
    func scheduleAlert(pillName: String, timeToTake: Date, message: String) {
        // create content of the notification
        let content = UNMutableNotificationContent()
        content.title = pillName
        content.sound = .default
        content.body = message
        
        let IDs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        
        for id in IDs {
        // set the triggering time (at the picked time from the datepicker)
            let targetTime = timeToTake.addingTimeInterval(TimeInterval(id * 60))
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute], from: targetTime), repeats: true)
            
            // request the UNNotificationCenter to send the notification with "content" at "trigger" time
            let request = UNNotificationRequest(identifier: "alarm_\(id)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: {error in
                if error != nil {
                    print("something is wrong")
                }
            })
        }
    }
    
    // remove all notications
    func cancelNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests();
        UNUserNotificationCenter.current().removeAllDeliveredNotifications();
    }
    
    
    @IBAction func didTapOnOff(_ sender: Any) {
        if ledOnOff.title == "On" {
            ledOnOff.title = "Off"
            var value: UInt8 = 1
            let dataOn = NSData(bytes: &value, length: MemoryLayout<UInt8>.size)
            sendDataToCentral(peripheral: peripheralAlert!, characteristic: onOffCharateristic!, data: dataOn)
        } else {
            ledOnOff.title = "On"
            var value: UInt8 = 0
            let dataOff = NSData(bytes: &value, length: MemoryLayout<UInt8>.size)
            sendDataToCentral(peripheral: peripheralAlert!, characteristic: onOffCharateristic!, data: dataOff)
        }
    }
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = model[indexPath.row].title
        let date = model[indexPath.row].time
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        cell.detailTextLabel?.text = formatter.string(from: date)
        return cell
    }
    
    // delete the tableView cell and clear the related notifications
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            model.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .bottom)
            cancelNotification()
        }
    }
}

extension ViewController {

    // ----------------Central Methods--------------------
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Unknown")
        case .unsupported:
            print("Unsupported")
        case .resetting:
            print("Resetting")
        case .unauthorized:
            print("Unauthorized")
        case .poweredOff:
            print("Bluetooth is powered off")
        case .poweredOn:
            print("Bluetooth is powered on")
            
            // central manager scan for peripheral device with given service UUID
            centralManager?.scanForPeripherals(withServices: [Alert_Service_UUID])
        @unknown default:
            fatalError("A fatal error occurred")
        }
            
    }
    
    // calls when discovering a service with given UUID
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral.name!)
        // store the peripheral object
        peripheralAlert = peripheral
        // set the peripheral delegate to the view controller itself
        peripheralAlert?.delegate = self
        // central manager stop scan for peripheral service
        centralManager?.stopScan()
        
        // central manager try to connect to the stored peripheral
        centralManager?.connect(peripheralAlert!)
    }
    
    // calls when connection is successful
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // central manager look for service with given UUID
        peripheralAlert?.discoverServices([Alert_Service_UUID])
        BLE_Is_Connected_Flag = true;
        // re-schedule the notification
        cancelNotification()
        scheduleAlert(pillName: pillNameStorage, timeToTake: timeToTakeStorage, message: "It's time to take your medicine!")
    }
    
    // calls when disconnected to the peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from the peripheral")
        BLE_Is_Connected_Flag = false;
        // re-schedule the notification
        cancelNotification()
        scheduleAlert(pillName: pillNameStorage, timeToTake: timeToTakeStorage, message: "It seems you're far away from your medication. Better to pick up your bottle and take your medicine")
        // central manager restart to look for peripherals
        centralManager?.scanForPeripherals(withServices: [Alert_Service_UUID])
    }
    
    // ----------------Peripheral Methods--------------------
    
    // calls when the service is discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if service.uuid == Alert_Service_UUID {
                print("Service: \(service)")
                
                // peripheral look for characteristics
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    // calls when the characteristics are found
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            if characteristic.uuid == Mag_Connection_Status_UUID {
                // read the value from the characteristic
                print("Characteristic: \(characteristic)")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == LED_UUID {
                onOffCharateristic = characteristic
                print("Characteristic: \(characteristic)")
            }
        }
    }
    
    // calls when the value of characteristic is updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == Mag_Connection_Status_UUID {
            Bottle_Is_Connected_Flag = deriveMagConnectionStatus(using: characteristic)
            print(Bottle_Is_Connected_Flag)
            var delayTime = 0
            if !Bottle_Is_Connected_Flag {
                cancelNotification()
                let currentTime = Date();
                delayTime = Int(currentTime.timeIntervalSince1970 - timeToTakeStorage.timeIntervalSince1970)
            } else {
                scheduleAlert(pillName: pillNameStorage, timeToTake: timeToTakeStorage.addingTimeInterval(TimeInterval(delayTime)), message: "It's time to take your medicine")
            }
        }
    }
    
    func deriveMagConnectionStatus(using statusCharacteristic: CBCharacteristic) -> Bool {
        let statusValue: Data = statusCharacteristic.value!
        let buffer = [UInt8](statusValue)
        if buffer[0] == 1 {
            return true
        } else {
            return false
        }
    }
    
    func sendDataToCentral(peripheral: CBPeripheral, characteristic: CBCharacteristic, data: NSData) {
        peripheral.writeValue(data as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("A write error occurred")
        }
    }
}



// properties of the reminder
struct Reminder {
    let title: String
    let time: Date
    let identifier: String
}
