/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  static let geocoder = CLGeocoder()
  var window: UIWindow?
  
  let center = UNUserNotificationCenter.current()
  let locationManager = CLLocationManager()
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    let rayWenderlichColor = UIColor(red: 76/255, green: 160/255, blue: 235/255, alpha: 1)
    UITabBar.appearance().tintColor = rayWenderlichColor
    
    locationManager.requestAlwaysAuthorization()
    locationManager.startMonitoringVisits()
    locationManager.delegate = self
    
    center.requestAuthorization(options: [.alert, .sound]) {  granted, error in
      
    }
    
    locationManager.distanceFilter = 35
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.startUpdatingLocation()
    return true
  }
}

extension AppDelegate: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
    // create CLLocation from the coordinates of CLVisit
    let clLocation = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)

    // Get location description
    AppDelegate.geocoder.reverseGeocodeLocation(clLocation) { placemarks , _ in
      if let place = placemarks?.first {
        let description = "\(place)"
        self.newVisitReceived(visit, description: description)
      }
    }
  }

  func newVisitReceived(_ visit: CLVisit, description: String) {
    let location = Location(visit: visit, descriptionString: description)
    LocationsStorage.shared.saveLocationOnDisk(location)

    //1
    let content = UNMutableNotificationContent()
    content.title = "New Location Entry"
    content.body = location.description
    content.sound = .default
    
    //2
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: location.dateString, content: content, trigger: trigger)
    
    //3
    center.add(request, withCompletionHandler: nil)
    
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //1
    guard let location = locations.first else {
      return
    }
    
    //2
    AppDelegate.geocoder.reverseGeocodeLocation(location) { placemarks, _ in
      
      if let place = placemarks?.first {
        //3
        let description = "Fake Visit: \(place)"
        
        //4
        let fakeVisit = FakeVisit(
          coordinates : location.coordinate,
          arrivalDate: Date(),
          departureDate: Date())
        
        self.newVisitReceived(fakeVisit, description: description)
      }
    }
  }
}

final class FakeVisit: CLVisit {
  
  private let myCoordinates: CLLocationCoordinate2D
  private let myArrivalDate: Date
  private let myDepartureDate: Date
  
  override var coordinate: CLLocationCoordinate2D {
    return myCoordinates
  }
  
  override var arrivalDate: Date {
    return myArrivalDate
  }
  
  override var departureDate: Date {
    return myDepartureDate
  }
  
  init(coordinates: CLLocationCoordinate2D, arrivalDate: Date, departureDate: Date){
    myCoordinates = coordinates
    myArrivalDate = arrivalDate
    myDepartureDate = departureDate
    super.init()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
