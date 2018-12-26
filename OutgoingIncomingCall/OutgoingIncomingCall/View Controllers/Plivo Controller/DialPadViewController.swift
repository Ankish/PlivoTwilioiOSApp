//
//  ViewController.swift
//  OutgoingIncomingCall
//
//  Created by Plivo on 12/7/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import UIKit
import AVFoundation
//Note: Remove the next line - libPhoneNumber_iOS and remove from pod if you dont intend to use libPhoneNumber_iOS to format the numbers
import libPhoneNumber_iOS

class DialPadViewController: UIViewController {

    // MARK: - class method
    /**
     *  Story BoardController
     *
     * Initiate DialPadViewController
     */
    class func storyBoardController() -> DialPadViewController {
        let vc : DialPadViewController = UIStoryboard.init(name: "Plivo", bundle: nil).instantiateViewController(withIdentifier: "DialPadViewController") as! DialPadViewController
        
        return vc
    }
    
    // MARK: - Outlet variables
    @IBOutlet private weak var callButton: UIButton!
    @IBOutlet private weak var dialPadContainerView: JCDialPad!
    @IBOutlet private weak var numberText: UITextField!
    @IBOutlet private weak var textFieldSplitter: UIView!
    @IBOutlet private weak var clearButton: UIImageView!
    
    //Set true - if Allowed to type SIP URI else set it to false.
    private var allowSipURI : Bool = true

    // MARK: - Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        dialPadContainerView.layoutIfNeeded()
        dialPadContainerView.setNeedsLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppUtility.lockOrientation(.portrait)
        SIPManager.sharedInstance.setPlivoDelegate(AppDelegate.shared)
    }
    
    
    // MARK: - Private methods
    private func setUp() {
        
        //Configuring UI Elements
        reset()
        numberText.placeholder = NSLocalizedString("Enter Number or an Endpoint URI", comment: "")
        dialPadContainerView?.buttons = JCDialPad.defaultButtons()
        dialPadContainerView?.delegate = self
        dialPadContainerView?.showDeleteButton = false
        dialPadContainerView?.formatTextToPhoneNumber = true
        dialPadContainerView?.digitsTextField.isHidden = true
        dialPadContainerView?.backgroundColor = UIColor.white
        dialPadContainerView?.mainColor = UIColor.black
        dialPadContainerView?.buttons.forEach {
            ($0 as? JCPadButton)?.borderColor = UIColor.black
            ($0 as? JCPadButton)?.textColor = UIColor.black
            ($0 as? JCPadButton)?.selectedColor = UIColor.black.withAlphaComponent(0.5)
        }
        numberText.text = ""
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapped))
        self.view.addGestureRecognizer(tapGesture)
        
        clearButton.isUserInteractionEnabled = true
        let clearGesture = UITapGestureRecognizer(target: self, action: #selector(clearAction(_:)))
        self.clearButton.addGestureRecognizer(clearGesture)
        
        self.textFieldSplitter.backgroundColor = UIColor.black
        numberText.delegate = self
    }
    
    /**
     *
     * Resetting the UI
     * Inorder to make new call
     *
     */
    private func reset() {
        //numberText.text = ""
        dialPadContainerView?.digitsTextField.text = ""
        dialPadContainerView?.rawText = ""
        numberText.isEnabled = allowSipURI
    }
    
    // MARK: - Action methods
    
    /**
     *
     * User to clear the Dialpad textfield
     *
     */
    @IBAction func clearAction(_ sender: Any) {
        dialPadContainerView?.didTapDeleteButton(clearButton)
        numberText.text = numberFormat(text : dialPadContainerView?.digitsTextField.text ?? "",needToFormat : true)
    }
    
    /**
     *
     * Initiate the call if entered text is valid
     * Else,throw an alert.
     *
     */
    @IBAction func callButtonAction(_ sender: Any) {
        let number : String?
        
        if let numberText = self.dialPadContainerView.rawText,!numberText.isEmpty {
            number = numberText
        } else if let numberText = self.numberText?.text,!numberText.isEmpty {
            number = numberText
        } else  {
            number = nil
        }
        
        if let number = number {
            func openCallController(type : SipType) {
                reset()
                let callController = CallViewController.storyBoardControllerForOutGoing(callerId: AppUtility.getUserNameWithoutDomain(number), isOutGoing: true,sipType : type)
                self.present(callController, animated: true, completion: nil)
            }
            
            let alert = UIAlertController(title: NSLocalizedString("Choose your provider", comment: ""), message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Plivo", comment: ""), style: .default, handler: { (action) in
                openCallController(type: .plivo)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Twilio", comment: ""), style: .default, handler: { (action) in
                openCallController(type: .twilio)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            
        } else {
            self.showAlert(title: NSLocalizedString("Invalid Number", comment: ""), message: NSLocalizedString("Please enter a valid phone number", comment: ""))
        }
        
    }
    
    @objc
    private func didTapped() {
        self.view.endEditing(true)
    }
    
    // MARK: - libPhoneNumber_iOS
    private func numberFormat(text : String,needToFormat : Bool) -> String {
        
        if needToFormat {
            let formatter = NBAsYouTypeFormatter(regionCode: NSLocale.current.regionCode)
            return formatter?.inputString(text) ?? ""
        } else {
            return text
        }
    }
    
    /**
     * Note: Remove the previous function and Uncomment the following function if you dont intend to use libPhoneNumber_iOS to format the numbers
     *
    private func numberFormat(text : String,needToFormat : Bool) -> String {
       return text
    }
    */
}

// MARK: - JCDialPadDelegates
extension DialPadViewController : JCDialPadDelegate {
    
    func dialPad(_ dialPad: JCDialPad, shouldInsertText text: String, forButtonPress button: JCPadButton) -> Bool {
        numberText.text = ""
        numberText.isEnabled = false
        return true
    }
    
    func dialPad(_ dialPad: JCDialPad, shouldInsertText text: String, forLongButtonPress button: JCPadButton) -> Bool {
        numberText.text = ""
        numberText.isEnabled = false
        return true
    }
    
    func getDtmfText(_ dtmfText: String, withAppendStirng appendText: String) {
        if appendText.isEmpty {
           if allowSipURI {
                numberText.isEnabled = true
            }
            numberText.text = ""
        } else {
            numberText.text = numberFormat(text : appendText,needToFormat : true)
        }
    }
}
// MARK: - UITextFieldDelegate
extension DialPadViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        dialPadContainerView?.rawText = ""
        dialPadContainerView?.digitsTextField.text = ""
        return true
    }
}
