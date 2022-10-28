//
//  ViewController.swift
//  App Location Manager
//
//  Created by Rohit Chauhan on 23/10/22.

import Combine
import UIKit
import LocationManager

class ViewController: UIViewController {
    var subscriptions:Set<AnyCancellable> = Set<AnyCancellable>()
    let subject = Publishers.locationSubjet(locationConfig: LocationManagerConfig(), totalRequestedValue: .max(1))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subject.sink { completion in
            debugPrint("Completion = \(completion)")
        } receiveValue: { receivedLocation in
            debugPrint("Location = \(receivedLocation)")
        }.store(in: &subscriptions)

    }


}

