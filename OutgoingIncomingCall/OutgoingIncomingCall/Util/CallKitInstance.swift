//
//  CallKitInstance.swift
//  OutgoingIncomingCall
//
//  Created by Ankish Jain on 12/17/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import Foundation
import CallKit
import AVFoundation
import PlivoVoiceKit

/**
 *
 * CallKitInstance
 * Handle All the Callkit related functinality
 *
 */
class CallKitInstance: NSObject,CXProviderDelegate, CXCallObserverDelegate {
    
    // MARK: - static variables
    //Singleton instance
    static let sharedInstance = CallKitInstance()
    
    // MARK: - properties
    private(set) var callUUID: UUID? 
    private(set) var callKitProvider: CXProvider?
    private(set) var callKitCallController: CXCallController?
    private(set) var callObserver: CXCallObserver?
    private(set) var handle : String?
    
    // MARK: - Initializers
    override init() {
        super.init()
        
        let configuration = CXProviderConfiguration(localizedName: "PTwilio")
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        callKitProvider = CXProvider(configuration: configuration)
        callKitCallController = CXCallController()
        callObserver = CXCallObserver()
        
        callKitProvider?.setDelegate(self, queue: DispatchQueue.main)
        callObserver?.setDelegate(self, queue: DispatchQueue.main)
    }
    
    public func reset() {
        callUUID = nil
        handle = nil
    }
    
    
    // MARK: - CallKit Actions
    /* reportOutGoingCall
     * Need to call while placing an outgoing call,
     * which will initiate callkit instance method
     *
     */
    public func reportOutGoingCall(with uuid: UUID, handle: String,completion : @escaping (Bool)->Void) {
        if AppUtility.isNetworkAvailable(){
            switch AVAudioSession.sharedInstance().recordPermission {
                
            case AVAudioSession.RecordPermission.granted:
                Logger.logDebug(tag: "CallKitInstance", message:"Permission granted")
                Logger.logDebug(tag: "CallKitInstance", message:String(format : "Outgoing call uuid is: %@", uuid.uuidString))
                Logger.logDebug(tag: "CallKitInstance", message:"provider:performStartCallActionWithUUID:");
                
                let callHandle = CXHandle(type: .generic, value: handle)
                let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
                let transaction = CXTransaction(action:startCallAction)
                callUUID = nil
                CallKitInstance.sharedInstance.callKitCallController?.request(transaction, completion: {(_ error: Error?) -> Void in
                    if error != nil {
                        Logger.logDebug(tag: "CallKitInstance", message: String(format : "StartCallAction transaction request failed: %@", error.debugDescription))
                        DispatchQueue.main.async(execute: {() -> Void in
                            Logger.logError(tag: "CallKitInstance", message: "Call start Action Failed")
                        })
                        completion(false)
                    }
                    else {
                        Logger.logDebug(tag: "CallKitInstance", message:"StartCallAction transaction request successful");
                        let callUpdate = CXCallUpdate()
                        callUpdate.remoteHandle = callHandle
                        callUpdate.supportsDTMF = true
                        callUpdate.supportsHolding = true
                        callUpdate.supportsGrouping = false
                        callUpdate.supportsUngrouping = false
                        callUpdate.hasVideo = false
                        
                        self.callUUID = uuid
                        self.handle = handle
                        
                        DispatchQueue.main.async(execute: {() -> Void in
                            CallKitInstance.sharedInstance.callKitProvider?.reportOutgoingCall(with: uuid, startedConnectingAt: Date())
                        })
                        
                        completion(true)
                    }
                })
                break
            case AVAudioSession.RecordPermission.denied:
                Logger.logError(tag: "CallKitInstance", message:"Please go to settings and turn on Microphone service for incoming/outgoing calls.")
                break
            case AVAudioSession.RecordPermission.undetermined:
                // This is the initial state before a user has made any choice
                // You can use this spot to request permission here if you want
                break
            default:
                break
            }
            
        } else{
            Logger.logError(tag: "CallKitInstance", message: "No Internet Connection")
        }
        
    }
    
    /* performEndCallAction
     *
     * Need to call when hanging up any call
     *
     */
    public func performEndCallAction(with uuid: UUID) {
        DispatchQueue.main.async(execute: {() -> Void in
            Logger.logDebug(tag: "CallKitInstance", message: String(format : "performEndCallActionWithUUID: %@",uuid.uuidString))
            let endCallAction = CXEndCallAction(call: uuid)
            let trasanction = CXTransaction(action:endCallAction)
            CallKitInstance.sharedInstance.callKitCallController?.request(trasanction, completion: {(_ error: Error?) -> Void in
                if error != nil {
                    Logger.logError(tag: "CallKitInstance", message:String(format : "EndCallAction transaction request failed: %@", error.debugDescription))
                    
                    DispatchQueue.main.async(execute: {() -> Void in
                        SIPManager.sharedInstance.stopAudioDevice()
                    })
                } else {
                    Logger.logError(tag: "CallKitInstance", message:"EndCallAction transaction request successful")
                }
            })
        })
    }
    
    /* performEndCallAction
     *
     * Need to call when new incoming voip comes.
     *
     */
    public func reportNewIncomingCall(from : String,callUUID : UUID?) -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            
            Logger.logDebug(tag: "CallKitInstance", message: "Permission granted")
            
            if let uuid = callUUID {
                self.callUUID = uuid
            } else {
                self.callUUID = UUID()
            }
            
            reportIncomingCall(from: from, with: CallKitInstance.sharedInstance.callUUID!)
            return true
        case AVAudioSession.RecordPermission.denied:
            Logger.logDebug(tag: "CallKitInstance", message:"Pemission denied")
            return false
        case AVAudioSession.RecordPermission.undetermined:
            Logger.logDebug(tag: "CallKitInstance", message:"Request permission here")
            return false
        default:
            return false
        }
    }
    
    private func reportIncomingCall(from: String, with uuid: UUID) {
        let callHandle = CXHandle(type: .generic, value: from)
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = true
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false
        
        handle = from
        
        CallKitInstance.sharedInstance.callKitProvider?.reportNewIncomingCall(with: uuid, update: callUpdate, completion: {(_ error: Error?) -> Void in
            if error != nil {
                Logger.logDebug(tag: "CallKitInstance", message: String(format : "Failed to report incoming call successfully: %@", error.debugDescription))
                SIPManager.sharedInstance.stopAudioDevice()
            } else {
                Logger.logDebug(tag: "CallKitInstance", message:"Incoming call successfully reported.");
                SIPManager.sharedInstance.configureAudioSession()
            }
        })
    }
    
    // MARK: - CXCallObserverDelegate
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded == true {
            Logger.logDebug(tag: "CallKitInstance", message:"CXCallState : Disconnected")
        } else  if call.hasConnected == true {
            Logger.logDebug(tag: "CallKitInstance", message:"CXCallState : Connected");
        } else if call.isOutgoing == true {
            Logger.logDebug(tag: "CallKitInstance", message:"CXCallState : Dialing");
        } else {
            Logger.logDebug(tag: "CallKitInstance", message:"CXCallState : Incoming");
        }
    }
    
    
    // MARK: - CXProvider Handling
    func providerDidReset(_ provider: CXProvider) {
        Logger.logDebug(tag: "CallKitInstance", message:"ProviderDidReset");
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        Logger.logDebug(tag: "CallKitInstance", message:"providerDidBegin");
    }
    
    /* didActivate
     *
     * Need to start your audio Device
     *
     */
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        Logger.logDebug(tag: "CallKitInstance", message:"provider:didActivateAudioSession");
        SIPManager.sharedInstance.startAudioDevice()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        Logger.logDebug(tag: "CallKitInstance", message:"provider:didDeactivateAudioSession:");
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        Logger.logDebug(tag: "CallKitInstance", message:"provider:timedOutPerformingAction:");
    }
    
    /* CXStartCallAction
     *
     * Trigger when Audio Session is configured
     * Need to create Outgoing call
     *
     */
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        Logger.logDebug(tag: "CallKitInstance", message:"provider:CXStartCallAction:");
       
        SIPManager.sharedInstance.configureAudioSession()
        
        let dest: String = action.handle.value
        
        //Make the call
        SIPManager.sharedInstance.call(withDest : dest,uuid : action.uuid) { (isSuccess) in
            if isSuccess {
                action.fulfill()
            } else {
                action.fail()
            }
        }
        
    }
    
    /* CXSetHeldCallAction
     *
     * Trigger when user press held button from Callkit UI
     *
     */
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        if action.isOnHold {
            SIPManager.sharedInstance.stopAudioDevice()
        } else {
            SIPManager.sharedInstance.startAudioDevice()
        }
        action.fulfill()
    }
    
    /* CXSetMutedCallAction
     *
     * Trigger when user press mute/unmute button from Callkit UI
     *
     */
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
       SIPManager.sharedInstance.isMuted = action.isMuted
    }
    
    /* CXAnswerCallAction
     *
     * Trigger when user answer the incoming call
     *
     */
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        Logger.logDebug(tag: "CallKitInstance", message:"provider:performAnswerCallAction:");
        
        //Answer the call
        CallKitInstance.sharedInstance.callUUID = action.callUUID
        SIPManager.sharedInstance.didAnsweredIncomingCall()
        
        let callController = CallViewController.storyBoardControllerForOutGoing(callerId: handle ?? "", isOutGoing: false,sipType : SIPManager.sharedInstance.currentCallType)
        AppDelegate.topViewController()?.present(callController, animated: true, completion: nil)
        
        action.fulfill()
    }
    
    /* CXPlayDTMFCallAction
     *
     * Trigger when user enter the number from CallKit UI
     *
     */
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        Logger.logDebug(tag: "CallKitInstance", message:"provider:performPlayDTMFCallAction:");
        let dtmfDigits: String = action.digits
        SIPManager.sharedInstance.sendDigits(digits: dtmfDigits)
        action.fulfill()
    }
    
    /* CXEndCallAction
     *
     * Trigger when user hangup the call from CallKit UI
     *
     */
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        DispatchQueue.main.async(execute: {() -> Void in
            Logger.logDebug(tag: "CallKitInstance", message:"provider:performEndCallAction:");
            SIPManager.sharedInstance.hangUp()
            action.fulfill()
        })
    }

}
