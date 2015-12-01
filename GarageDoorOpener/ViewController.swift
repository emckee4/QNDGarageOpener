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

    override func viewWillAppear(animated: Bool) {
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
            case .EnableBluetooth: UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            default: btManager.proceedWithSetup()
        }
    }
    
    
    func btStateChanged(state: BTPrepSteps) {
        switch state {
        case .EnableBluetooth:
            self.infoLabel.text = "Bluetooth may be off"
            button.setTitle("Open Settings", forState: .Normal)
        case .Ready:
            button.setTitle("Open/Close", forState: .Normal)
            self.infoLabel.text = "Ready..."
        default:
            button.setTitle("Retry Connection", forState: .Normal)
            self.infoLabel.text = "Connecting..."
        }
    }

    func writeResults(success:Bool){
        button.backgroundColor = success ? UIColor.greenColor() : UIColor.redColor()
        UIView.animateWithDuration(0.75, animations: { () -> Void in
            self.button.backgroundColor = self.baseButtonColor
        })
    }
}

