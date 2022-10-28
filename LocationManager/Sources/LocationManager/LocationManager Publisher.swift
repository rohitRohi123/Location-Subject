import Combine
import CoreLocation

public extension Publishers {
   static func locationSubjet(locationConfig:
                              LocationManagerConfig = LocationManagerConfig(),
                              totalRequestedValue: Subscribers.Demand = .unlimited)-> AnyPublisher<[CLLocation], Error> {
       return LocationSubject(locationConfig: locationConfig, totalRequestedValue: totalRequestedValue).eraseToAnyPublisher()
    }
    
}

public extension Publishers {
    static func distanceBetween(coordinate1: CLLocation, coordinate2: CLLocation)-> AnyPublisher<CLLocationDistance, Never> {
        return Just(coordinate1.distance(from: coordinate2)).eraseToAnyPublisher()
    }
}


final class LocationSubject:NSObject, Publisher {
    typealias Output = [CLLocation]
    typealias Failure = Error
   
    private var completion: Subscribers.Completion<Failure>? = nil

    private let locationConfig: LocationManagerConfig
    private var requestedValue: Subscribers.Demand = .none
    private var subscriptions: [Int : LocationSubscription<Output, Failure>] = [:]
    
    private let lock: NSRecursiveLock = NSRecursiveLock()
    
    private var locationManager: CLLocationManager?
    
    public init(locationConfig:
         LocationManagerConfig = LocationManagerConfig(),
         totalRequestedValue: Subscribers.Demand = .unlimited) {
        self.locationManager = CLLocationManager()
        self.locationManager?.desiredAccuracy = locationConfig.desiredAccuracy
        self.locationManager?.distanceFilter = locationConfig.distancefilter
        
        self.locationConfig = locationConfig
        self.requestedValue = totalRequestedValue
    }
    
    private func receiveCompletion(completion:
                                   Subscribers.Completion<Failure>,
                                   _ index: Int) {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        self.completion = completion
        self.subscriptions.removeValue(forKey: index)
    }
    
}

extension LocationSubject {
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, [CLLocation] == S.Input {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        guard !isCompleted(),
              let locationManager = self.locationManager else {
            return
        }
        
        let subscription = LocationSubscription(subscriber: subscriber,
                                                locationManager: locationManager,
                                                index: self.subscriptions.count,
                                                requestedValue: self.requestedValue,
                                                completion: receiveCompletion)
        self.subscriptions[self.subscriptions.count] = subscription
        
        if self.subscriptions.count == 1 {
            self.locationManager?.delegate = self
            self.locationManager?.requestWhenInUseAuthorization()
            self.locationManager?.startUpdatingLocation()
        }
        
        subscriber.receive(subscription: subscription)
    }
    
}

extension LocationSubject {
    private func isCompleted()-> Bool {
        guard let completion = completion else {
            return false
        }

        self.locationManager?.stopUpdatingLocation()
        self.locationManager = nil
        
        self.subscriptions.values.forEach { $0.receive(completion: completion) }
        
        return true
    }
    
}

extension LocationSubject: CLLocationManagerDelegate {
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        
        if let completion = self.completion,
            self.subscriptions.count > 0 {
            self.subscriptions.values.forEach { $0.receive(completion: completion) }
            return
        }
        
        self.subscriptions.values.forEach { $0.receive(value: locations) }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if #available(iOS 14.0, macOS 11.0, watchOS 7.0, *) {
            guard manager.authorizationStatus != .notDetermined else {
                return
            }
        } else {
            guard CLLocationManager.authorizationStatus() != .notDetermined else {
                return
            }
        }
        
        self.subscriptions.values.forEach { $0.receive(completion: Subscribers.Completion.failure(error)) }
    }
    
    
    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            guard self.requestedValue == .unlimited else {
                return
            }
        
            switch status {
                case .authorizedWhenInUse:
                    if #available(iOS 13.4, *) {
                        self.locationManager?.requestAlwaysAuthorization()
                    }else {
                        self.locationManager?.requestAlwaysAuthorization()
                    }
                case .notDetermined:
                    debugPrint("notDetermined")
                case .restricted:
                    debugPrint("restricted")
                case .denied:
                    debugPrint("denied")
                default:
                    break
            }
        
      }
}


public struct LocationManagerConfig {
    public init(desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest, distancefilter: CLLocationDistance = kCLDistanceFilterNone) {
        self.desiredAccuracy = desiredAccuracy
        self.distancefilter = desiredAccuracy
    }
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    var distancefilter: CLLocationDistance = kCLDistanceFilterNone
}

