//
//  ViewController.swift
//  TestBluetoothApp
//
//  Created by Mikhail Malaschenko on 11.12.21.
//

import UIKit

final class ViewController: UIViewController {

    @IBOutlet private weak var bpmValuesLabel: UILabel!
    @IBOutlet private weak var bodyLocationLabel: UILabel!
    @IBOutlet private weak var connectButton: UIButton!
    @IBOutlet private weak var disconnectButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private var manager: BLEManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    @IBAction private func connectButtonPressed(_ sender: UIButton) {
        manager?.connect()
    }

    @IBAction private func disconnectButtonPressed(_ sender: UIButton) {
        manager?.disconnect()
    }
    
    private func configure() {
        manager = BLEManager()
        manager?.delegate = self
        
        bodyLocationLabel.text = ""
        bpmValuesLabel.text = ""
    }

}

extension ViewController: BLEManagerDelegate {
    
    func getStatus(status: String?) {
        showAlert(message: status)
    }
    
    func getLocationValue(value: String?) {
        bodyLocationLabel.text = value
    }
    
    func getValues(value: String?) {
        bpmValuesLabel.text = value
    }
    
    func statusConnecting(status: Status) {
        switch status {
        case .connecting:
            connecting()
            print(status.rawValue)
        case .connect:
            connect()
            print(status.rawValue)
        case .disconnect:
            disconnect()
            print(status.rawValue)
        }
    }
    
    private func connecting() {
        activityIndicator.startAnimating()
        connectButton.isEnabled = false
        connectButton.setTitle(Constants.Text.connecting.uppercased(), for: .normal)
    }
    
    private func connect() {
        activityIndicator.stopAnimating()
        connectButton.isEnabled = false
        connectButton.setTitle(Constants.Text.connected.uppercased(), for: .normal)
    }
    
    private func disconnect() {
        bodyLocationLabel.text = ""
        bpmValuesLabel.text = ""
        activityIndicator.stopAnimating()
        connectButton.isEnabled = true
        connectButton.setTitle(Constants.Text.connect.uppercased(), for: .normal)
    }
    
    private func showAlert(message: String?) {
        let alert = UIAlertController(title: nil,
                                      message: message,
                                      preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(action)
        present(alert, animated: true)
    }
    
}

