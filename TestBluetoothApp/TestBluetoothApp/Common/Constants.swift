//
//  Constants.swift
//  TestBluetoothApp
//
//  Created by Mikhail Malaschenko on 23.01.22.
//

import Foundation
import CoreBluetooth

struct Constants {
    struct Text {
        static let disconnect = "Disconnect"
        static let connected = "Connected"
        static let connecting = "Connecting"
        static let connect = "Connect"
        static let checkBluetoothState = "Check the Bluetooth status or permission to use Bluetooth on your device."
        static let notFind = "Couldn't find device nearby, turn on the device and try again"
        static let other = "Other"
        static let chest = "Chest"
        static let arm = "Arm"
        static let finger = "Finger"
        static let palm = "Palm"
        static let ear = "Ear"
        static let leg = "Leg"
        static let reserve = "Reserve"
    }
    struct CBIdentifiers  {
        static let heartRateUUID = CBUUID(string: "0x180D")
        static let heartRateCharacteristicCBUUID = CBUUID(string: "2A37")
        static let bodyLocationCharacteristicCBUUID = CBUUID(string: "2A38")
    }
    
    struct Numbers {
        static let timeout: Double = 5
    }
}
