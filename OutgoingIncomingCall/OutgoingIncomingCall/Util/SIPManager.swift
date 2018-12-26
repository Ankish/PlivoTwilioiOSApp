//
//  CallManager.swift
//  OutgoingIncomingCall
//
//  Created by Ankish Jain on 12/21/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import Foundation
import PlivoVoiceKit
import TwilioVoice

class SIPManager : NSObject {
    
    // MARK: - static variables
    //Singleton instance
    static let sharedInstance = SIPManager()
    
    // MARK: - private variables
    private let plivoManager = PlivoManager()
    private let twilioManager = TwilioManager()
    
    // MARK: - public variables
    public var currentCallType : SipType = .plivo
    
    // MARK: - public variables
    public var isMuted: Bool = false {
        didSet {
            switch currentCallType {
            case .plivo:
                plivoManager.isMuted = isMuted
            case .twilio:
                twilioManager.isMuted = isMuted
            }
        }
    }
    
    public var isHold: Bool = false {
        didSet {
            switch currentCallType {
            case .plivo:
                plivoManager.isHold = isMuted
            case .twilio:
                twilioManager.isHold = isMuted
            }
        }
    }
    
    // MARK: - Initializers
    override init() {
        super.init()
        
    }
    
    // MARK: - Methods
    public func incomingCallFromPlivo(incoming: PlivoIncoming) {
        self.currentCallType = .plivo
        plivoManager.didReceivedIncomingCall(incoming: incoming)
    }
    
    public func incomingCallFromTwilio(callInvite: TVOCallInvite) {
        self.currentCallType = .twilio
        twilioManager.didReceivedIncomingCall(incoming : callInvite)
    }
    
    public func didAnsweredIncomingCall() {
        switch currentCallType {
        case .plivo:
            plivoManager.didAnsweredIncomingCall()
        case .twilio:
            twilioManager.didAnsweredIncomingCall()
        }
    }
    
    // To register with SIP Server
    func loginForPlivo(withUserName userName: String, andPassword password: String) {
        plivoManager.login(withUserName: userName, andPassword: password)
    }
    
    //To unregister with SIP Server
    func logout(type : SipType) {
        switch type {
        case .plivo:
            plivoManager.logout()
        case .twilio:
            twilioManager.logout()
        }
    }
    
    //To call sip/number
    func call(withDest dest: String,uuid : UUID,completion : @escaping (Bool)->Void) {
        switch currentCallType {
        case .plivo:
            plivoManager.call(withDest: dest, completion: completion)
        case .twilio:
            twilioManager.call(withDest: dest,uuid : uuid,completion: completion)
        }
    }
    
    func setPlivoDelegate(_ controllerDelegate: NSObject) {
        plivoManager.setDelegate(controllerDelegate)
    }
    
    func setTwiloDelegate(_ delegate : TVOCallDelegate) {
        twilioManager.setDelegate(delegate)
    }
    
    //Register pushkit token
    func registerToken(_ token: Data) {
        plivoManager.registerToken(token)
        twilioManager.registerToken(token)
    }
    
    func unRegisterToken() {
        plivoManager.unRegisterToken()
        twilioManager.unRegisterToken()
    }
    
    //receive and pass on (information or a message)
    func relayVoipPushNotification(_ pushdata: [AnyHashable: Any],delegate : NSObject) {
        Logger.logDebug(tag: "SIPManager", message: "\(pushdata)")
        switch currentCallType {
        case .plivo:
            plivoManager.setDelegate(delegate)
            plivoManager.relayVoipPushNotification(pushdata)
        case .twilio:
            twilioManager.relayVoipPushNotification(pushdata,delegate : delegate)
        }
    }
    
    func sendDigits(digits : String) {
        switch currentCallType {
        case .plivo:
            plivoManager.sendDigits(digits : digits)
        case .twilio:
            twilioManager.sendDigits(digits : digits)
        }
    }
    
    //To Configure Audio
    func configureAudioSession() {
        switch currentCallType {
        case .plivo:
            plivoManager.configureAudioSession()
        case .twilio:
            twilioManager.configureAudioSession()
        }
    }
    
    /*
     * To Start Audio service
     * To handle Audio Interruptions
     * AVAudioSessionInterruptionTypeEnded
     */
    func startAudioDevice() {
        switch currentCallType {
        case .plivo:
            plivoManager.startAudioDevice()
        case .twilio:
            twilioManager.startAudioDevice()
        }
    }
    
    /*
     * To Start Audio service
     * To handle Audio Interruptions
     * AVAudioSessionInterruptionTypeBegan
     */
    func stopAudioDevice() {
        switch currentCallType {
        case .plivo:
            plivoManager.stopAudioDevice()
        case .twilio:
            twilioManager.stopAudioDevice()
        }
    }
    
    /*
     * To Hang up Outgoing Call
     *
     */
    func hangUp() {
        switch currentCallType {
        case .plivo:
            plivoManager.hangUp()
        case .twilio:
            twilioManager.hangUp()
        }
    }
    
}
