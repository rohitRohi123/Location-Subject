# LocationSubject

- LocationSubject, a publisher to get current loction or continous location update.

- LocationManagerConfig - Used to set location accuracy and distance filter

- Usages 

- Publishers.locationSubjet(locationConfig:LocationManagerConfig, totalRequestedValue: Subscribers.Demand)

- Get Location finite time -  totalRequestedValue: .max(finite number)

- Continously get location -  totalRequestedValue: .unlimited - Default value
 


