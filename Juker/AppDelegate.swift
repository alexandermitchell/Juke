//
//  AppDelegate.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-06-10.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var auth = SPTAuth()

    // MARK: - Life Cycle Functions
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        auth.redirectURL = URL(string: ConfigCreds.redirectURLString)
        auth.sessionUserDefaultsKey = "current session"
        
        
        //MARK: Save Session (Currently Disabled)
        
        //Right now, our access token is only valid for 60 min. It is not possible to receive a refresh token from Spotify without implementing our own server. This is something that will be implemented in a future build.
        
        // Please excuse the commented code below. It is disabled right now for demonstration purposes :)
        
        //If there is an active session - unarchive it and segue to userType VC, else show login vc to get a new session.
        
//        if let sessionObj:Any = UserDefaults.standard.object(forKey: "SpotifySession") as Any? {
//            let sessionDataObj = sessionObj as! Data
//            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
//            
//            //set session on instantiated VC to be firstTimeSession
//            
//            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
//            let initialViewController : UserTypeViewController = mainStoryboard.instantiateViewController(withIdentifier: "userType") as! UserTypeViewController
//            initialViewController.session = firstTimeSession
//            self.window = UIWindow(frame: UIScreen.main.bounds)
//            self.window?.rootViewController = initialViewController
//            self.window?.makeKeyAndVisible()
//            return true
//        }

        
        return true
        
    }

    
    // 1
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // 2- check if app can handle redirect URL
        if auth.canHandle(auth.redirectURL) {
            // 3 - handle callback in closure
            auth.handleAuthCallback(withTriggeredAuthURL: url, callback: { (error, session) in
                // 4- handle error
                if error != nil {
                    print("error!")
                }
                // 5- Add session to User Defaults
                let userDefaults = UserDefaults.standard
                let sessionData = NSKeyedArchiver.archivedData(withRootObject: session!)
                userDefaults.set(sessionData, forKey: "SpotifySession")
                userDefaults.synchronize()
                // 6 - Tell notification center login is successful
                NotificationCenter.default.post(name: Notification.Name(rawValue: "loginSuccessfull"), object: nil)
            })
            return true
        }
        return false
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
       // self.saveContext()
    }
}

