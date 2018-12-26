//
//  PlivoManager.swift
//  OutgoingIncomingCall
//
//  Created by Plivo on 12/7/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import Foundation
import PlivoVoiceKit

/**
 *
 * PlivoManager
 * Manages all the communication between Client and Plivo
 *
 * Need to call the method setCallDelegate / setLoginDelegate (based on required feature) inorder to
 * get respective callbacks
 *
 */
class PlivoManager : NSObject {
    
    // MARK: - private variables
    private var endpoint: PlivoEndpoint = PlivoEndpoint(debug: true)
    private(set) var outCall: PlivoOutgoing?
    private(set) var inCall :  PlivoIncoming?
    
    // MARK: - public variables
    public var isMuted: Bool = false {
        didSet {
            if isMuted {
                outCall?.mute()
            } else {
                outCall?.unmute()
            }
        }
    }
    
    public var isHold: Bool = false {
        didSet {
            if isHold {
                outCall?.hold()
                self.stopAudioDevice()
            } else {
                outCall?.unhold()
                self.startAudioDevice()
            }
        }
    }
    
    // MARK: - Initializers
    override init() {
        super.init()
        
    }
    
    // MARK: - Methods
    
    // To register with SIP Server
    func login(withUserName userName: String, andPassword password: String) {
        endpoint.login(userName, andPassword: password)
    }
    
    //To unregister with SIP Server
    func logout() {
        endpoint.logout()
    }
    
    //To call sip/number
    func call(withDest dest: String,completion : @escaping (Bool)->Void) {
        func isValidEmail(str:String) -> Bool {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            
            let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailTest.evaluate(with: str)
        }
        
        var sipUri: String = "sip:\(dest)@phone.plivo.com"
        if dest.contains("sip:"){
            sipUri = dest
        } else if isValidEmail(str: dest){
            sipUri = dest
        }
        
        //Set extra headers
        let headers: [AnyHashable: Any] = [
            "X-PH-Header1" : "Value1",
            "X-PH-Header2" : "Value2"
        ]
        
        if let call = endpoint.createOutgoingCall() {
            outCall = call
            outCall?.call(sipUri, headers: headers)
            completion(true)
        } else {
            completion(false)
        }
    }
    
    func setDelegate(_ controllerDelegate: NSObject) {
        endpoint.delegate = controllerDelegate
    }

    //Incoming call
    func didReceivedIncomingCall(incoming: PlivoIncoming) {
        if (self.inCall == nil && self.outCall == nil) {
            /* log it */
            Logger.logDebug(tag: "PlivoManager", message:String(format : "Incoming Call from %@", incoming.fromContact))
            Logger.logDebug(tag: "PlivoManager", message:"Call id in incoming is:")
            Logger.logDebug(tag: "PlivoManager", message:incoming.callId)
            /* assign incCall var */
            self.setUpIncomingCall(incomingCall: incoming)

            let isSuccess = CallKitInstance.sharedInstance.reportNewIncomingCall(from: incoming.fromUser, callUUID: nil)
            
            if !isSuccess {
                incoming.reject()
            }
            
        } else {
            /*
             * Reject the call when we already have active ongoing call
             */
            incoming.reject()
            return
        }
    }
    
    func didAnsweredIncomingCall() {
        self.inCall?.answer()
    }
    
    //Register pushkit token
    func registerToken(_ token: Data) {
        endpoint.registerToken(token)
    }
    
    func unRegisterToken() {
        
    }
    
    //receive and pass on (information or a message)
    func relayVoipPushNotification(_ pushdata: [AnyHashable: Any]) {
        endpoint.relayVoipPushNotification(pushdata)
    }
    
    func sendDigits(digits : String) {
        Logger.logDebug(tag: "PlivoManager", message: "sendDigits \(digits)")
        
        if (outCall != nil) {
            outCall?.sendDigits(digits)
        } else if (inCall != nil) {
            inCall?.sendDigits(digits)
        }
    }
    
    //To Configure Audio
    func configureAudioSession() {
        endpoint.configureAudioDevice()
    }
    
    /*
     * To Start Audio service
     * To handle Audio Interruptions
     * AVAudioSessionInterruptionTypeEnded
     */
    func startAudioDevice() {
        endpoint.startAudioDevice()
    }
    
    /*
     * To Start Audio service
     * To handle Audio Interruptions
     * AVAudioSessionInterruptionTypeBegan
     */
    func stopAudioDevice() {
        endpoint.stopAudioDevice()
    }
    
    /*
     * To Hang up Outgoing Call
     *
     */
    func hangUp() {
        Logger.logDebug(tag: "PlivoManager", message:"hangUp")
        self.stopAudioDevice()
        
        if let outCall = outCall {
            outCall.hangup()
        } else if let inCall = inCall {
            if inCall.state != Ongoing {
                inCall.reject()
            } else {
                inCall.hangup()
            }
        }
        
        if let uuid = CallKitInstance.sharedInstance.callUUID {
            CallKitInstance.sharedInstance.performEndCallAction(with: uuid)
        }
        
        self.inCall = nil
        self.outCall = nil
        
        CallKitInstance.sharedInstance.reset()
    }
    
    
    /*
     * Setting up the incoming Call
     */
    private func setUpIncomingCall(incomingCall : PlivoIncoming?) {
        self.inCall = incomingCall
    }
    
    /*
     * Setting up the outgoing Call
     */
    private func setUpOutGoingCall(outGoingCall : PlivoOutgoing?) {
        self.outCall = outGoingCall
    }
}
