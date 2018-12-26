//
//  TwilioManager.swift
//  OutgoingIncomingCall
//
//  Created by Ankish Jain on 12/21/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import Foundation
import TwilioVoice

class TwilioManager : NSObject {

    // MARK: - properties
    private(set) var call:TVOCall?
    private(set) var callInvite:TVOCallInvite?
    private var deviceTokenString:String?
    private var accessTokenString : String?
    
    private weak var delegate : TVOCallDelegate?
    
    //Configure your base url and acccess token endpoint
    private let baseURLString = "https://697602be.ngrok.io"
    private let accessTokenEndpoint = "/accessToken"
    private let twimlParamTo = "to"
    
    // MARK: - public variables
    public var isMuted: Bool = false {
        didSet {
            call?.isMuted = isMuted
        }
    }
    
    public var isHold: Bool = false {
        didSet {
            call?.isOnHold = isHold
            
            if isHold {
                self.stopAudioDevice()
            } else {
                self.startAudioDevice()
            }
            
        }
    }
    
    // MARK: - Initializers
    override init() {
        super.init()
        
        TwilioVoice.logLevel = .verbose
    }
    
    // MARK: - Methods
    private func getIdentity() -> String? {
        if let identity = UserDefaultManager.shared.value(forKey: .twilioIdentity) as? String,!identity.isEmpty {
            return identity
        } else {
            return nil
        }
    }
    
    private func fetchAccessToken() -> String? {
        guard let identity = getIdentity() else {
            return nil
        }
        
        if let accessTokenString = accessTokenString {
            return accessTokenString
        } else {
            let endpointWithIdentity = String(format: "%@?identity=%@", accessTokenEndpoint, identity)
            guard let accessTokenURL = URL(string: baseURLString + endpointWithIdentity) else {
                return nil
            }
            
            accessTokenString = try? String.init(contentsOf: accessTokenURL, encoding: .utf8)
            return accessTokenString
        }
    }
    
    //To unregister with SIP Server
    func logout() {
        
    }
    
    //Incoming call
    func didReceivedIncomingCall(incoming: TVOCallInvite) {
        if (self.call == nil && self.callInvite == nil) {
            /* log it */
            Logger.logDebug(tag: "TwiloManager", message:String(format : "Incoming Call from %@", incoming.from))
            Logger.logDebug(tag: "TwiloManager", message:"Call id in incoming is:")
            Logger.logDebug(tag: "TwiloManager", message:incoming.uuid.uuidString)
            /* assign incCall var */
            self.setUpIncomingCall(incomingCall: incoming)
            
            let isSuccess = CallKitInstance.sharedInstance.reportNewIncomingCall(from: incoming.from, callUUID: incoming.uuid)
            
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
        call = self.callInvite?.accept(with: self)
    }
    
    //To call sip/number
    func call(withDest dest: String,uuid : UUID,completion : @escaping (Bool)->Void) {
        guard let accessToken = fetchAccessToken() else {
            completion(false)
            return
        }
        
        call = TwilioVoice.call(accessToken, params: [twimlParamTo : dest], uuid:uuid, delegate: self)
        
    }
    
    func setDelegate(_ controllerDelegate: TVOCallDelegate?) {
        delegate = controllerDelegate
    }
    
    //Register pushkit token
    func registerToken(_ token: Data) {
        guard let accessToken = fetchAccessToken() else {
            return
        }
        
        TwilioVoice.register(withAccessToken: accessToken, deviceToken: (token as NSData).description) { (error) in
            if let error = error {
                Logger.logDebug(tag: "TwilioManager", message: "An error occurred while registering: \(error.localizedDescription)")
            } else {
                Logger.logDebug(tag: "TwilioManager", message:"Successfully registered for VoIP push notifications.")
            }
        }
        
        self.deviceTokenString = token.description
    }
    
    func unRegisterToken() {
        guard let deviceToken = deviceTokenString, let accessToken = fetchAccessToken() else {
            return
        }
        
        TwilioVoice.unregister(withAccessToken: accessToken, deviceToken: deviceToken) { (error) in
            if let error = error {
                Logger.logDebug(tag: "TwilioManager", message:"An error occurred while unregistering: \(error.localizedDescription)")
            }
            else {
                Logger.logDebug(tag: "TwilioManager", message:"Successfully unregistered from VoIP push notifications.")
            }
        }
        
        self.deviceTokenString = nil
    }
    
    //receive and pass on (information or a message)
    func relayVoipPushNotification(_ pushdata: [AnyHashable: Any],delegate : NSObject) {
        if let tvoDelegate = delegate as? TVONotificationDelegate {
            TwilioVoice.handleNotification(pushdata, delegate: tvoDelegate)
        }
    }
    
    func sendDigits(digits : String) {
        Logger.logDebug(tag: "TwilioManager", message: "sendDigits \(digits)")
        call?.sendDigits(digits)
    }
    
    //To Configure Audio
    func configureAudioSession() {
        TwilioVoice.configureAudioSession()
    }
    
    /*
     * To Start Audio service
     * To handle Audio Interruptions
     * AVAudioSessionInterruptionTypeEnded
     */
    func startAudioDevice() {
        TwilioVoice.isAudioEnabled = true
    }
    
    /*
     * To Start Audio service
     * To handle Audio Interruptions
     * AVAudioSessionInterruptionTypeBegan
     */
    func stopAudioDevice() {
        TwilioVoice.isAudioEnabled = false
    }
    
    /*
     * To Hang up Outgoing Call
     *
     */
    func hangUp() {
        Logger.logDebug(tag: "TwilioManager", message:"hangUp")
        
        self.stopAudioDevice()
        
        if (callInvite != nil && callInvite?.state == .pending) {
            callInvite?.reject()
            self.call?.disconnect()
        } else if let call = call,call.state != .disconnected {
            call.disconnect()
        }
        
        if let uuid = CallKitInstance.sharedInstance.callUUID {
            CallKitInstance.sharedInstance.performEndCallAction(with: uuid)
        }
        
        self.call = nil
        callInvite = nil
        CallKitInstance.sharedInstance.reset()
    }
    
    
    /*
     * Setting up the incoming Call
     */
    private func setUpIncomingCall(incomingCall : TVOCallInvite?) {
        self.callInvite = incomingCall
    }
    
    /*
     * Setting up the outgoing Call
     */
    private func setUpOutGoingCall(outGoingCall : TVOCall?) {
        self.call = outGoingCall
    }
    
}

// MARK: - TVOCallDelegate methods
extension TwilioManager : TVOCallDelegate {
    func callDidConnect(_ call: TVOCall) {
        CallKitInstance.sharedInstance.callKitProvider?.reportOutgoingCall(with: call.uuid, connectedAt: Date())
        delegate?.callDidConnect(call)
    }
    
    func call(_ call: TVOCall, didFailToConnectWithError error: Error) {
        delegate?.call(call,didFailToConnectWithError : error)
    }
    
    func call(_ call: TVOCall, didDisconnectWithError error: Error?) {
        delegate?.call(call,didDisconnectWithError : error)
    }
}
