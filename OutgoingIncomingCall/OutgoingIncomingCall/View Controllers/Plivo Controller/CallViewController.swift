//
//  CallViewController.swift
//  OutgoingIncomingCall
//
//  Created by Plivo on 12/7/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import UIKit
import PlivoVoiceKit
import AVFoundation
import TwilioVoice

/**
 *
 * CallViewController
 * Call Screen for outgoing call,which has following controls
 *
 * Mute/Unmute
 * Speaker Enable
 * Hold/Unhold
 * Hangup ongoing call
 *
 */
class CallViewController: UIViewController {

    /**
     *  Story BoardController
     *
     * Initiate CallViewController
     */
    // MARK: - class method
    class func storyBoardControllerForOutGoing(callerId: String,isOutGoing : Bool,sipType : SipType) -> CallViewController {
        let vc : CallViewController = UIStoryboard.init(name: "Plivo", bundle: nil).instantiateViewController(withIdentifier: "CallViewController") as! CallViewController
        vc.callerId = callerId
        vc.isOutGoing = isOutGoing
        vc.sipType = sipType
        return vc
    }
    
    // MARK: - Outlet variables
    @IBOutlet private weak var speakerButton: UIButton!
    @IBOutlet private weak var muteButton: UIButton!
    @IBOutlet private weak var hangUpButton: UIButton!
    @IBOutlet private weak var callingInfoLabel: UILabel!
    @IBOutlet private weak var holdButton: UIButton!
    @IBOutlet private weak var hideKeypadButton: UIButton!
    @IBOutlet private weak var keypadButton: UIButton!
    @IBOutlet private weak var controlsView: UIView!
    @IBOutlet private weak var dialPad: JCDialPad!
    
    // MARK: - Private Properties
    private var sipType : SipType = .plivo
    private var callerId: String = ""
    private var isOutGoing : Bool = false
    private var isMuted: Bool = false {
        didSet {
            //Updating the Mute button based on the user selection
            if isMuted {
                muteButton?.setImage(UIImage(named: "MuteIcon"), for: .normal)
            } else {
                muteButton?.setImage(UIImage(named: "Unmute"), for: .normal)
            }
        }
    }
    private var isHold: Bool = false {
        didSet {
            //Updating the hold button based on the user selection
            if isHold {
                holdButton.alpha = 1
            } else {
                holdButton.alpha = 0.5
            }
        }
    }
    
    private var isSpeakerOn: Bool = false {
        didSet {
            //Updating the Speaker button based on the user selection
            if isSpeakerOn {
                speakerButton?.setImage(UIImage(named: "Speaker_on"), for: .normal)
            } else {
                speakerButton?.setImage(UIImage(named: "Speaker"), for: .normal)
            }
        }
    }
    
    // MARK: - Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setting delegate for Plivo/Twilio call events listener.
        SIPManager.sharedInstance.currentCallType = sipType
        switch sipType {
        case .plivo:
            SIPManager.sharedInstance.setPlivoDelegate(self)
        case .twilio:
            SIPManager.sharedInstance.setTwiloDelegate(self)
        }
        
        setUp()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        dialPad.layoutIfNeeded()
        dialPad.setNeedsLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppUtility.lockOrientation(.portrait)
        
    }
    
    deinit {
        SIPManager.sharedInstance.setPlivoDelegate(AppDelegate.shared)
        Logger.logDebug(tag: "CallViewcontroller", message: "deinit")
    }
    
    // MARK: - Private methods
    private func setUp() {
        
        //configure UI items
        self.isMuted = false
        self.isHold = false
        self.isSpeakerOn = false
        dialPad?.buttons = JCDialPad.defaultButtons()
        dialPad?.delegate = self
        dialPad?.showDeleteButton = false
        dialPad?.formatTextToPhoneNumber = false
        dialPad?.digitsTextField.isHidden = true
        dialPad?.backgroundColor = UIColor.clear
        dialPad?.buttons.forEach {
            ($0 as? JCPadButton)?.borderColor = UIColor.white
            ($0 as? JCPadButton)?.textColor = UIColor.white
            ($0 as? JCPadButton)?.selectedColor = UIColor.white.withAlphaComponent(0.5)
        }
        
        /**
         *
         * Before Calling, you need to cofigure your audio Session
         * Once call created,need to startAudio Device
         *
         */
        if isOutGoing {
            disableAllControls()
            SIPManager.sharedInstance.configureAudioSession()
            CallKitInstance.sharedInstance.reportOutGoingCall(with: UUID(), handle: self.callerId) { [weak self] (isSucess) in
                if (!isSucess) {
                    self?.dismiss(animated: true, completion: nil)
                }
            }
            
            if SIPManager.sharedInstance.currentCallType == .plivo {
                self.callingInfoLabel.text = "Plivo : Calling \(callerId).."
            } else {
                self.callingInfoLabel.text = "Twilio : Calling \(callerId).."
            }
            
        } else {
            
            if SIPManager.sharedInstance.currentCallType == .plivo {
                self.callingInfoLabel.text = "Plivo : Call from \(callerId).."
            } else {
                self.callingInfoLabel.text = "Twilio : Call from \(callerId).."
            }
            
        }
        
    }
    
    private func enableAllControls() {
        self.holdButton.isEnabled = true
        self.speakerButton.isEnabled = true
        self.muteButton.isEnabled = true
    }
    
    private func disableAllControls() {
        self.holdButton.isEnabled = false
        self.speakerButton.isEnabled = false
        self.muteButton.isEnabled = false
    }
    
    // MARK: - Action Methods
    @IBAction func speakerAction(_ sender: Any) {
        handleSpeaker()
    }
    
    @IBAction func muteAction(_ sender: Any) {
        self.isMuted = !isMuted
        SIPManager.sharedInstance.isMuted = self.isMuted
    }
    
    @IBAction func hangUpAction(_ sender: Any) {
        Logger.logDebug(tag: "CallViewcontroller", message: "hangUpAction")
        SIPManager.sharedInstance.hangUp()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func holdAction(_ sender: Any) {
        self.isHold = !isHold
        SIPManager.sharedInstance.isHold = self.isHold
    }
    
    @IBAction func keypadAction(_ sender: Any) {
        UIView.animate(withDuration: 0.4, animations: {
            self.dialPad.alpha = 1
            self.controlsView.alpha = 0
            self.hideKeypadButton.alpha = 1
        })
    }
    
    @IBAction func hideKeypadAction(_ sender: Any) {
        UIView.animate(withDuration: 0.4, animations: {
            self.dialPad.alpha = 0
            self.controlsView.alpha = 1
            self.hideKeypadButton.alpha = 0
        })
    }
    
    private func handleSpeaker() {
        let audioSession = AVAudioSession.sharedInstance()
        if(isSpeakerOn) {
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
                isSpeakerOn = false
            } catch let error as NSError {
                Logger.logDebug(tag: "CallViewcontroller", message: "audioSession error: \(error.localizedDescription)")
            }
        } else {
            /* Enable Speaker Phone mode */
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                isSpeakerOn = true
            } catch let error as NSError {
                Logger.logDebug(tag: "CallViewcontroller", message: "audioSession error: \(error.localizedDescription)")
            }
        }
    }
    
    private func didConnected() {
        DispatchQueue.main.async {
            self.enableAllControls()
            
            if SIPManager.sharedInstance.currentCallType == .plivo {
                self.callingInfoLabel.text = "Plivo : Connected \(self.callerId)"
            } else {
                self.callingInfoLabel.text = "Twilio : Connected \(self.callerId)"
            }
            
        }
    }
    
    private func hangUp() {
        DispatchQueue.main.async {
            SIPManager.sharedInstance.hangUp()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
}

// MARK: - JCDialPadDelegates
extension CallViewController : JCDialPadDelegate {
    
    func dialPad(_ dialPad: JCDialPad, shouldInsertText text: String, forButtonPress button: JCPadButton) -> Bool {
        return true
    }
    
    func dialPad(_ dialPad: JCDialPad, shouldInsertText text: String, forLongButtonPress button: JCPadButton) -> Bool {
        return true
    }
    
    func getDtmfText(_ dtmfText: String, withAppendStirng appendText: String) {
        SIPManager.sharedInstance.sendDigits(digits : dtmfText)
    }
}

// MARK: - Plivo delegate
extension CallViewController : PlivoEndpointDelegate  {
    
    /**
     *
     * Trigger when outgoing call started to ring for other end
     * @Params
     * call - Outgoing call object which you created while placing the call.
     *
     */
    func onOutgoingCallRinging(_ call: PlivoOutgoing!) {
        DispatchQueue.main.async {
            Logger.logDebug(tag: "CallViewcontroller", message: "onOutgoingCallRinging")
            self.callingInfoLabel.text = "Ringing ..."
        }
    }
    
    /**
     *
     * Trigger when other person answered the outgoing call
     * @Params
     * call - Outgoing call object which you created while placing the call.
     *
     */
    func onOutgoingCallAnswered(_ call: PlivoOutgoing!) {
        Logger.logDebug(tag: "CallViewcontroller", message: "onOutgoingCallAnswered")
        didConnected()
    }
    
    /**
     *
     * Trigger when other person hangup the call
     * @Params
     * call - Outgoing call object which you created while placing the call.
     */
    func onOutgoingCallHangup(_ call: PlivoOutgoing!) {
        Logger.logDebug(tag: "CallViewcontroller", message: "onOutgoingCallHangup")
        hangUp()
    }
    
    /**
     *
     * Trigger when other person rejected the outgoing call
     * @Params
     * call - Outgoing call object which you created while placing the call.
     *
     */
    func onOutgoingCallRejected(_ call: PlivoOutgoing!) {
        DispatchQueue.main.async {
            Logger.logDebug(tag: "CallViewcontroller", message: "onOutgoingCallRejected")
            self.showAlert(title: NSLocalizedString("Rejected", comment: ""), message: NSLocalizedString("Your outgoing call has been rejected by the other person.", comment: ""),okAction: { (_) in
                self.hangUp()
            })
        }
    }
    
    /**
     *
     * Trigger when something went wrong while placing outgoing call
     * @Params
     * call - Outgoing call object which you created while placing the call.
     *
     */
    func onOutgoingCallInvalid(_ call: PlivoOutgoing!) {
        DispatchQueue.main.async {
            Logger.logDebug(tag: "CallViewcontroller", message: "onOutgoingCallInvalid")
            self.showAlert(title: NSLocalizedString("Invalid id", comment: ""), message: NSLocalizedString("You tried to call a wrong id/ Endpoint URI", comment: ""),okAction: { (_) in
                self.hangUp()
            })
        }
    }
    
    /* On an incoming call, if the call is disconnected by the caller, this delegate
     would be triggered with the PlivoIncoming object.
     */
    func onIncomingCallRejected(_ incoming : PlivoIncoming) {
        DispatchQueue.main.async {
            Logger.logDebug(tag: "CallViewcontroller", message: "onIncomingCallRejected")
            self.hangUp()
        }
    }
    
    /* On an incoming call, if the call is disconnected by the caller after being answered,
     this delegate would be triggered with the PlivoIncoming object.
     */
    func onIncomingCallHangup(_ incoming : PlivoIncoming) {
        Logger.logDebug(tag: "CallViewcontroller", message: "onIncomingCallHangup")
        hangUp()
    }
    
    /* On an active endpoint, this delegate would be called with the digit
     received on the call.
     */
    func onIncomingDigit(_ digit : String) {
        Logger.logDebug(tag: "CallViewcontroller", message: "onIncomingDigit \(digit)")
    }
}
// MARK: - Twilio delegate
extension CallViewController : TVOCallDelegate {
    
    func callDidConnect(_ call: TVOCall) {
        didConnected()
    }
    
    func call(_ call: TVOCall, didFailToConnectWithError error: Error) {
        DispatchQueue.main.async {
            Logger.logDebug(tag: "CallViewcontroller", message: "didFailToConnectWithError")
            self.showAlert(title: NSLocalizedString("Failed To Connect", comment: ""), message: error.localizedDescription,okAction: { (_) in
                self.hangUp()
            })
        }
    }
    
    func call(_ call: TVOCall, didDisconnectWithError error: Error?) {
        DispatchQueue.main.async {
            Logger.logDebug(tag: "CallViewcontroller", message: "didDisconnectWithError")
            self.showAlert(title: NSLocalizedString("Disconnected", comment: ""), message: error?.localizedDescription ?? NSLocalizedString("Call Disconnected", comment: ""),okAction: { (_) in
                self.hangUp()
            })
        }
    }
}
