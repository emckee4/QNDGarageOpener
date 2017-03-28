//
//  ViewController.swift
//  GarageDoorOpener
//
//  Created by Evan Mckee on 11/28/15.
//  Copyright © 2015 McKeeMaKer. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, BTManagerDelegate{

    @IBOutlet var button:UIButton!
    @IBOutlet var infoLabel:UILabel!
    
    var btManager:BluetoothManager!
    
    var baseButtonColor:UIColor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        btManager = BluetoothManager()
        btManager.delegate = self
        baseButtonColor = button.backgroundColor  //copying value from storyboard
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        if btManager.nextStepInReadiness != .Ready {
            infoLabel.text = "Reconnecting"
            findAndConnectGDR()
        } else {
            infoLabel.text = "Ready"
        }
    }
    

    
    func findAndConnectGDR(){
        btManager.proceedWithSetup()
    }
    
    
    @IBAction func buttonPressed(){
        switch btManager.nextStepInReadiness {
            case .Ready: btManager.writeOpenCloseCommand()
            case .EnableBluetooth: UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            default: btManager.proceedWithSetup()
        }
    }
    
    
    func btStateChanged(_ state: BTPrepSteps) {
        switch state {
        case .EnableBluetooth:
            self.infoLabel.text = "Bluetooth may be off"
            button.setTitle("Open Settings", for: UIControlState())
        case .Ready:
            button.setTitle("Open/Close", for: UIControlState())
            self.infoLabel.text = "Ready..."
        default:
            button.setTitle("Retry Connection", for: UIControlState())
            self.infoLabel.text = "Connecting..."
        }
    }

    func writeResults(_ success:Bool){
        button.backgroundColor = success ? UIColor.green : UIColor.red
        UIView.animate(withDuration: 0.75, animations: { () -> Void in
            self.button.backgroundColor = self.baseButtonColor
        })
    }
}

