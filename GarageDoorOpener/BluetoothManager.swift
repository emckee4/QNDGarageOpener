//
//  BluetoothManager.swift
//  GarageDoorOpener
//
//  Created by Evan Mckee on 11/28/15.
//  Copyright © 2015 McKeeMaKer. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothManager:NSObject, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    var centralManager:CBCentralManager!
    
    let beanName = "NDU Bean"
    let beanAdvertisedUUID = CBUUID(string: "A495FF10-C5B1-4B44-B512-1370F02D74DE")
    let beanScratchServiceUUID = CBUUID(string: "A495FF20-C5B1-4B44-B512-1370F02D74DE")
    let beanScratch1CharUUID = CBUUID(string: "A495FF21-C5B1-4B44-B512-1370F02D74DE")
    
    var bean:CBPeripheral?
    var scratchService:CBService?
    var scratch1Char:CBCharacteristic?
    
    var commandData:NSData = {
        let bytes:[UInt8] = [0xDD,0xDD]
        return NSData(bytes: bytes, length: 2)
    }()
    
    var unitIsReady:Bool {
        return (bean != nil && bean!.state == .Connected && scratchService != nil && scratch1Char != nil)
    }
    
    var nextStepInReadiness:BTPrepSteps {
        guard centralManager != nil && centralManager.state == .PoweredOn else {return .EnableBluetooth}
        guard bean != nil else {return .Scan}
        guard bean!.state == .Connected else {return .Connect}
        guard scratchService != nil else {return .DiscoverService}
        guard scratch1Char != nil else {return .DiscoverCharacteristic}
        return .Ready
    }
    
    var delegate:BTManagerDelegate?
    
    override init(){
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
    }
    
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("didDiscoverPeripheral: \(peripheral.name), \(peripheral.services)")
        if peripheral.name == beanName{
            print("connecting...")
            centralManager.stopScan()
            bean = peripheral
            bean!.delegate = self
            proceedWithSetup()
        }
        
    }
    
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("didConnect")
//        if scratchService == nil {
//            peripheral.discoverServices([beanScratchServiceUUID])
//        }
        bean = peripheral
        bean!.delegate = self
        proceedWithSetup()
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didDisconnect")
        proceedWithSetup()
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didFailToConnect:")
        proceedWithSetup()
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        proceedWithSetup()
    }
    
    
    
    //MARK:- Peripheral delegate
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("didDiscoverCharacteristicsForService \(service)" )
        if let scratchChar = service.characteristics?.filter({$0.UUID == beanScratch1CharUUID}).first {
            self.scratch1Char = scratchChar
        } else {
            centralManager.cancelPeripheralConnection(bean!)
        }
        proceedWithSetup()
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("didDiscoverServices \(peripheral.services)")
        if let scratch = peripheral.services?.filter({$0.UUID == beanScratchServiceUUID}).first {
            scratchService = scratch
            
        } else {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        proceedWithSetup()
    }
    
    
    ///Using write with response is necessary to trigger the pairing dialog. The side effect is that it gives us feed back for visual display to the user, though the door opening and closing should be feedback enough.
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("didWriteValueForCharacteristic: \(error)")
        if error == nil {
            self.delegate?.writeResults(true)
        } else {
            print("didWriteValueForCharacteristic: Error: \(error!)")
            self.delegate?.writeResults(false)
        }
    }
    
    ///Proceed with setup drives the pairing process through the numerous steps that must occur before we can send messages
    func proceedWithSetup(){
        print("proceed: \(nextStepInReadiness)")
        self.delegate?.btStateChanged(nextStepInReadiness)
        switch nextStepInReadiness {
        case .EnableBluetooth: break
        case .Scan: centralManager.scanForPeripheralsWithServices([beanAdvertisedUUID], options: nil)
        case .Connect: centralManager.connectPeripheral(bean!, options: nil)
        case .DiscoverService: bean!.discoverServices([beanScratchServiceUUID])
        case .DiscoverCharacteristic: bean!.discoverCharacteristics([beanScratch1CharUUID], forService: scratchService!)
        case .Ready: break
        }
    }
    
    func writeOpenCloseCommand(){
        if nextStepInReadiness == .Ready {
            bean!.writeValue(commandData, forCharacteristic: scratch1Char!, type: .WithResponse)
        }
    }
}

protocol BTManagerDelegate {
    func btStateChanged(state:BTPrepSteps)
    func writeResults(success:Bool)
}


enum BTPrepSteps:String {
    case EnableBluetooth = "EnableBT",
    Scan = "Scan",
    Connect = "Connect",
    DiscoverService = "DiscoverService",
    DiscoverCharacteristic = "DiscoverCharacteristic",
    Ready = "Ready"
}


/*

[
<CBService: 0x1456209f0, isPrimary = YES, UUID = F000FFC0-0451-4000-B000-000000000000>,
<CBService: 0x145620bd0, isPrimary = YES, UUID = Device Information>, 
<CBService: 0x145620c10, isPrimary = YES, UUID = A495FF10-C5B1-4B44-B512-1370F02D74DE>,
<CBService: 0x145620c70, isPrimary = YES, UUID = A495FF20-C5B1-4B44-B512-1370F02D74DE>, // want scratch1: A495FF21-C5B1-4B44-B512-1370F02D74DE
<CBService: 0x14561baf0, isPrimary = YES, UUID = Battery>
]

*/



