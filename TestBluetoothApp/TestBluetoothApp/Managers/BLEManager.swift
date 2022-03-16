//
//  BLEManager.swift
//  TestBluetoothApp
//
//  Created by Mikhail Malaschenko on 14.03.22.
//

import Foundation
import CoreBluetooth

protocol BLEManagerDelegate: AnyObject {
    
    func getStatus(status: String?)
    func getLocationValue(value: String?)
    func getValues(value: String?)
    func statusConnecting(status: Status)
}

enum Status: String {
    case connecting
    case connect
    case disconnect
}

public final class BLEManager: NSObject {
    
    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var timer: Timer?
    
    private let heartRateUUID = Constants.CBIdentifiers.heartRateUUID
    private let heartRateCharacteristicCBUUID = Constants.CBIdentifiers.heartRateCharacteristicCBUUID
    private let bodyLocationCharacteristicCBUUID = Constants.CBIdentifiers.bodyLocationCharacteristicCBUUID
    
    weak var delegate: BLEManagerDelegate?
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    public func connect() {
        if centralManager?.state == .poweredOn {
            startTimer()
            centralManager?.scanForPeripherals(withServices: [heartRateUUID])
            delegate?.statusConnecting(status: .connecting)
        } else {
            delegate?.getStatus(status: Constants.Text.checkBluetoothState)
        }
    }
    
    public func disconnect() {
        stopTimer()
        delegate?.statusConnecting(status: .disconnect)
        centralManager?.stopScan()
        guard let strongPeripheral = peripheral else { return }
        centralManager?.cancelPeripheralConnection(strongPeripheral)
        peripheral = nil
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: Constants.Numbers.timeout,
                                     target: self,
                                     selector: #selector(timeoutHandler(_:)),
                                     userInfo: nil,
                                     repeats: false)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func timeoutHandler(_ sandler: Timer) {
        disconnect()
        delegate?.getStatus(status: Constants.Text.notFind)
    }
    
    private func bodyLocation(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = characteristic.value,
              let byte = characteristicData.first else { return "Error" }
        switch byte {
        case 0: return Constants.Text.other
        case 1: return Constants.Text.chest
        case 2: return Constants.Text.arm
        case 3: return Constants.Text.finger
        case 4: return Constants.Text.palm
        case 5: return Constants.Text.ear
        case 6: return Constants.Text.leg
        default:
            return Constants.Text.reserve
        }
    }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            return Int(byteArray[1])
        } else {
            return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown, .resetting, .unsupported, .unauthorized, .poweredOff:
            delegate?.getStatus(status: Constants.Text.checkBluetoothState)
        default:
            break
        }
        delegate?.statusConnecting(status: .disconnect)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        stopTimer()
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        centralManager?.stopScan()
        centralManager?.connect(peripheral, options: nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.getStatus(status: "\(Constants.Text.connected) to \(peripheral.name ?? "")")
        delegate?.statusConnecting(status: .connect)
        self.peripheral?.discoverServices([heartRateUUID])
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let status: String
        if let error = error {
            status = error.localizedDescription
            print(error.localizedDescription)
            centralManager?.cancelPeripheralConnection(peripheral)
        } else {
            status = Constants.Text.disconnect
        }
        stopTimer()
        delegate?.getStatus(status: status)
        delegate?.statusConnecting(status: .disconnect)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            delegate?.getStatus(status: error.localizedDescription)
            centralManager?.cancelPeripheralConnection(peripheral)
            print(error.localizedDescription)
        }
        stopTimer()
        delegate?.statusConnecting(status: .disconnect)
    }
}

extension BLEManager: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            delegate?.getStatus(status: error.localizedDescription)
            print(error.localizedDescription)
            return
        }
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            delegate?.getStatus(status: error.localizedDescription)
            print(error.localizedDescription)
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            peripheral.readValue(for: characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        switch characteristic.uuid {
        case bodyLocationCharacteristicCBUUID:
            let bodyLocationCharacteristic = bodyLocation(from: characteristic)
            delegate?.getLocationValue(value: bodyLocationCharacteristic)
            
        case heartRateCharacteristicCBUUID:
            let bpm = heartRate(from: characteristic)
            delegate?.getValues(value: String(bpm))
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}
