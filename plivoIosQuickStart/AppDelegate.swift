//
//  AppDelegate.swift
//  plivoIosQuickStart
//
//  Created by Altanai Bisht on 30/10/18.
//  Copyright © 2018 Altanai Bisht. All rights reserved.
//

import UIKit
import PushKit
import AVFoundation
import Intents
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    private func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //For VOIP Notificaitons
        if #available(iOS 10.0, *)
        {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                // Enable or disable features based on authorization.
            }
            application.registerForRemoteNotifications()
        }
        
        //Request Record permission
        let session = AVAudioSession.sharedInstance()
        if (session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("granted")
                    
                    do {
                        //try session.setCategory(AVAudioSession.Category.playAndRecord)
                        try session.setActive(true)
                    }
                    catch {
                        
                        print("Couldn't set Audio session category")
                    }
                } else{
                    print("not granted")
                }
            })
        }
        
        //One time signIn
        //Save User's credentials in NSUserDefaults
        //Check Authenticaiton status
        if UtilClass.getUserAuthenticationStatus() {
            //Default View Controller: ContactsViewController
            //Landing page
            let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarContrler: UITabBarController? = _mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
           
            //Get Username and Password from NSUserDefaults and Login
//            Phone.sharedInstance.login(withUserName: UserDefaults.standard.object(forKey: kUSERNAME) as! String, andPassword: UserDefaults.standard.object(forKey: kPASSWORD) as! String)
        }

        
        return true
    }
    
    // Register for VoIP notifications
    func voipRegistration() {
        
        let mainQueue = DispatchQueue.main
        // Create a push registry object
        let voipResistry = PKPushRegistry(queue: mainQueue)
        // Set the registry's delegate to self
        voipResistry.delegate = (self as? PKPushRegistryDelegate)
        //Set the push type to VOIP
        voipResistry.desiredPushTypes = Set<AnyHashable>([PKPushType.voIP]) as? Set<PKPushType>
    }
    
    // MARK: PKPushRegistryDelegate
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        
        NSLog("pushRegistry:didUpdatePushCredentials:forType:");
        
        if credentials.token.count == 0 {
            print("VOIP token NULL")
            return
        }
        print("Credentials token: \(credentials.token)")
        Phone.sharedInstance.registerToken(credentials.token)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        NSLog("pushRegistry:didInvalidatePushTokenForType:")
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        
        NSLog("pushRegistry:didReceiveIncomingPushWithPayload:forType:")
        
        if (type == PKPushType.voIP) {
            
            DispatchQueue.main.async(execute: {() -> Void in
                Phone.sharedInstance.relayVoipPushNotification(payload.dictionaryPayload)
            })
        }
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (_ options: UNNotificationPresentationOptions) -> Void) {
        //Called when a notification is delivered to a foreground app.
        print("willPresentNotification Userinfo \(notification.request.content.userInfo)")
        completionHandler(.alert)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //Called to let your app know which action was selected by the user for a given notification.
        print("didReceiveNotificationResponse Userinfo \(response.notification.request.content.userInfo)")
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
    }
    
    @nonobjc func application(_ app: UIApplication, open url: URL, options: [String: Any]) -> Bool {
        
        return application(app, processOpenURLAction: url, sourceApplication:UIApplication.OpenURLOptionsKey.sourceApplication.rawValue, annotation: UIApplication.OpenURLOptionsKey.annotation, iosVersion: 9)
        
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return self.application(application, processOpenURLAction: url, sourceApplication: sourceApplication!, annotation: annotation, iosVersion: 8)
    }
    
    func application(_ application: UIApplication, processOpenURLAction url: URL, sourceApplication: String, annotation: Any, iosVersion version: Int) -> Bool {
        //Deep linking
        let latlngArray: [Any] = url.absoluteString.components(separatedBy: "://")
        //handleDeepLinking(latlngArray[1] as! String)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping (_ restorableObjects: [Any]?) -> Void) -> Bool {
        if UtilClass.getUserAuthenticationStatus() {
            //When user taps on iPhone's native call list
            //This method will be called only if the call is related to Plivo
            let interaction: INInteraction? = userActivity.interaction
            let startAudioCallIntent: INStartAudioCallIntent? = (interaction?.intent as? INStartAudioCallIntent)
            let contact: INPerson? = startAudioCallIntent?.contacts?[0]
            print("\(String(describing: contact?.displayName))")
            let personHandle: INPersonHandle? = contact?.personHandle
            let contactValue: String? = personHandle?.value
            
            return true
        }
        else {
            print("Please login to make a call");
            return false
        }
    }
    
//    func handleDeepLinking(_ phoneNumber: String) {
//
//        //Maintaining unique Call Id
//        //Singleton
//        CallKitInstance.sharedInstance.callUUID = UUID()
//        //PlivoCallController handles the incoming/outgoing calls
//        let _mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let tabBarContrler: UITabBarController? = _mainStoryboard.instantiateViewController(withIdentifier: "tabBarViewController") as? UITabBarController
//        let plivoVC: PlivoCallController? = (tabBarContrler?.viewControllers?[2] as? PlivoCallController)
//        tabBarContrler?.selectedViewController = tabBarContrler?.viewControllers?[2]
//        Phone.sharedInstance.setDelegate(plivoVC!)
//        plivoVC?.performStartCallAction(with: CallKitInstance.sharedInstance.callUUID!, handle: phoneNumber)
//        window?.rootViewController = tabBarContrler
//    }
}

