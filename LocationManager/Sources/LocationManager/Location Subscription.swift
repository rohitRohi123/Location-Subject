//  Created by Rohit Chauhan on 26/10/22.
//

import Combine
import CoreLocation

final class LocationSubscription<Output, Failure: Error>: Subscription {
    private var completion: ((Subscribers.Completion<Failure>, _ index: Int)-> Void)? = nil
    private var subscriber: AnySubscriber<Output, Failure>?
    private var locationManager: CLLocationManager?
    private var index: Int
    private var requestDemand: Subscribers.Demand
    
    init<S>(subscriber: S,
            locationManager: CLLocationManager,
            index: Int,
            requestedValue: Subscribers.Demand,
            completion:@escaping ((Subscribers.Completion<Failure>, _ index: Int)-> Void)) where S: Subscriber,
                                                      Output == S.Input,
                                                      Failure == S.Failure {
        self.subscriber = AnySubscriber(subscriber)
        self.locationManager = locationManager
        self.completion = completion
        self.index = index
        self.requestDemand = requestedValue
    }
    
}

extension LocationSubscription {
    func receive(completion: Subscribers.Completion<Failure>) {
        guard let subscriber = self.subscriber else {return }
        
        self.subscriber = nil
        
        self.locationManager?.stopUpdatingLocation()
        self.locationManager = nil
        self.completion = nil
        self.completion?(completion, self.index)
        subscriber.receive(completion: completion)
    }
    
    func receive(value: Output) {
        if let _ = subscriber?.receive(value) {
            requestDemand -= .max(1)
        }
        
        guard self.requestDemand > .none else {
              cancel()
            return
        }
        
    }
    
}

extension LocationSubscription {
    func request(_ demand: Subscribers.Demand) {
        
    }
    
    func cancel() {
        self.receive(completion: .finished)
       
    }
    
}
