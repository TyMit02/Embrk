//
//  AppDelegate.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/8/24.
//


import SwiftUI
import FirebaseCore
import FirebaseAuth
import HealthKit

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    do {
        try FirebaseApp.configure()
        print("DEBUG: Firebase configured successfully")
    } catch {
        print("DEBUG: Error configuring Firebase: \(error.localizedDescription)")
    }
    Auth.auth().useAppLanguage()
    Auth.auth().setAPNSToken(Data(), type: .unknown)

    if HKHealthStore.isHealthDataAvailable() {
        print("DEBUG: HealthKit is available on this device")
        requestHealthKitPermissions()
    } else {
        print("DEBUG: HealthKit is not available on this device")
    }

    return true
  }

  func requestHealthKitPermissions() {
    guard let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) else {
        print("DEBUG: Step Count is not available")
        return
    }

    let healthStore = HKHealthStore()
    healthStore.requestAuthorization(toShare: [], read: [stepCount]) { (success, error) in
        if success {
            print("DEBUG: HealthKit authorization granted")
        } else if let error = error {
            print("DEBUG: HealthKit authorization failed: \(error.localizedDescription)")
        }
    }
  }
}
