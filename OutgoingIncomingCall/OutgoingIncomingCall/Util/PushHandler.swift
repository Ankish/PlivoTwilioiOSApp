//
//  PushHandler.swift
//  OutgoingIncomingCall
//
//  Created by Ankish Jain on 12/19/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import Foundation
import UserNotifications
import PushKit
import PlivoVoiceKit
import TwilioVoice

extension AppDelegate :PKPushRegistryDelegate,UNUserNotificationCenterDelegate,PlivoEndpointDelegate,TVONotificationDelegate  {
    
    // Register for VoIP notifications
    func voipRegistration() {
        Logger.logDebug(tag: "Appdelegate",message:"voipRegistration")
        let mainQueue = DispatchQueue.main
        // Create a push registry object
        let voipResistry = PKPushRegistry(queue: mainQueue)
        // Set the registry's delegate to self
        voipResistry.delegate = self as PKPushRegistryDelegate
        //Set the push type to VOIP
        voipResistry.desiredPushTypes = Set<AnyHashable>([PKPushType.voIP]) as? Set<PKPushType>
    }
    
    // MARK: PKPushRegistryDelegate
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        Logger.logDebug(tag: "Appdelegate",message:"pushRegistry:didInvalidatePushTokenForType:")
            
        SIPManager.sharedInstance.unRegisterToken()
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        Logger.logDebug(tag: "Appdelegate", message:"pushRegistry:didUpdatePushCredentials:forType:");
        
        if credentials.token.count == 0 {
            print("VOIP token NULL")
            return
        }
            
        Logger.logDebug(tag: "Appdelegate", message: "Credentials token: \(credentials.type)")
        Logger.logDebug(tag: "Appdelegate", message: "Credentials token: \(credentials.token)")
        SIPManager.sharedInstance.registerToken(credentials.token)
        
    }
    
    /* didReceiveIncomingPushWith
     * Received Voip push,hand over the data to Plivo SDK,that will trigger onIncomingCall method.
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        Logger.logDebug(tag: "Appdelegate",message:"pushRegistry:didReceiveIncomingPushWithPayload:forType:")
        
        if (type == PKPushType.voIP) {
            DispatchQueue.main.async(execute: {() -> Void in
                
                if let dict = payload.dictionaryPayload["aps"] as? [String : Any],let type = dict["alert"] as? String,type == "plivo" {
                    print(dict)
                    SIPManager.sharedInstance.currentCallType = .plivo
                } else {
                    SIPManager.sharedInstance.currentCallType = .twilio
                }
                
                SIPManager.sharedInstance.relayVoipPushNotification(payload.dictionaryPayload, delegate: self)
            })
        }
    }
    
    
    // MARK: - PlivoEndpointDelegate method
    /* On an incoming call to a registered endpoint, this delegate receives
     a PlivoIncoming object.
     */
    func onIncomingCall(_ incoming: PlivoIncoming) {
        SIPManager.sharedInstance.incomingCallFromPlivo(incoming : incoming)
    }
    
    
    // MARK: TVONotificaitonDelegate
    func callInviteReceived(_ callInvite: TVOCallInvite) {
        SIPManager.sharedInstance.incomingCallFromTwilio(callInvite : callInvite)
    }
    
    func notificationError(_ error: Error) {
        Logger.logError(tag: "PushHandler", message: error.localizedDescription)
    }
    
    //TopView controller
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        
        if let split = base as? UISplitViewController {
            if split.viewControllers.count > 1 {
                if split.viewControllers[1].presentedViewController != nil {
                    return topViewController(base: split.viewControllers[1])
                } else {
                    return topViewController(base: split.viewControllers.first)
                }
            } else if let controller = split.viewControllers.first {
                return topViewController(base: controller)
            }
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
    
    
}
