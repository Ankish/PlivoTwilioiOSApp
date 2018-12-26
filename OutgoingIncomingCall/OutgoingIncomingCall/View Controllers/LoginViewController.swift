//
//  LoginViewController.swift
//  OutgoingIncomingCall
//
//  Created by Plivo on 12/7/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import UIKit
import PlivoVoiceKit

class LoginViewController: UITableViewController {

    // MARK: - class method
    /**
     *  Story BoardController
     *
     * Initiate DialPadViewController
     */
    class func storyBoardController() -> LoginViewController {
        let vc : LoginViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        
        return vc
    }
    
    // MARK: - Outlet variables
    @IBOutlet private weak var plivoSignInButton: UIButton!
    @IBOutlet private weak var plivoUserNameField: UITextField!
    @IBOutlet private weak var plivoPasswordField: UITextField!
    @IBOutlet private weak var passwordCell: UITableViewCell!
    @IBOutlet private weak var twilioSignInButton: UIButton!
    @IBOutlet private weak var twilioUsername: UITextField!
    @IBOutlet private weak var plivoLogo: UIImageView!
    
    private let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private let plivoColor = UIColor.init(red: 0.1686, green: 0.6901, blue: 0.1921, alpha: 1)
    
    // MARK: - Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SIPManager.sharedInstance.setPlivoDelegate(self)
        
        setUp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppUtility.lockOrientation(.all)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.activityIndicator.center = self.view.center
        
        self.plivoSignInButton?.layer.cornerRadius = (self.plivoSignInButton?.frame.height ?? 0) / 2
        self.twilioSignInButton?.layer.cornerRadius = (self.twilioSignInButton?.frame.height ?? 0) / 2
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Private methods
    
    /**
     * Initial setup for UI and adding table view delegate and regerstring cells
     */
    
    private func setUp() {
        // adding observers for the keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.plivoUserNameField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Plivo Username", comment: ""), attributes: [NSAttributedString.Key.foregroundColor : UIColor.black.withAlphaComponent(0.5)])
        self.plivoUserNameField.delegate = self
    
        self.plivoPasswordField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Plivo Password", comment: ""), attributes: [NSAttributedString.Key.foregroundColor : UIColor.black.withAlphaComponent(0.5)])
        self.plivoPasswordField.isSecureTextEntry = true
        self.plivoPasswordField.delegate = self
        
        self.twilioUsername.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Twilio Username", comment: ""), attributes: [NSAttributedString.Key.foregroundColor : UIColor.black.withAlphaComponent(0.5)])
        self.twilioUsername.delegate = self
        
        self.plivoSignInButton.setTitle(NSLocalizedString("PLIVO LOGIN", comment: ""), for: .normal)
        self.twilioSignInButton.setTitle(NSLocalizedString("TWILIO LOGIN", comment: ""), for: .normal)
        self.enableLogin()
        
        self.plivoUserNameField.text = ""
        self.plivoPasswordField.text = ""
        
        self.view.addSubview(activityIndicator)
        activityIndicator.color = UIColor.black
        
        plivoLogo.layer.cornerRadius = 5
        
        self.tableView.backgroundColor = UIColor.white
        self.tableView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
    
    }
    
    func showActivityIndicator() {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }
    
    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
    /**
     * returns the indexpath of the cell in which the view presented.
     */
    func indexPath(forView: UIView) -> IndexPath? {
        let viewCenterRelativeToTableview = self.tableView.convert(CGPoint.init(x: forView.bounds.midX, y: forView.bounds.midY), from: forView)
        return self.tableView.indexPathForRow(at: viewCenterRelativeToTableview)
    }
    
    private func disableLogin() {
        self.plivoSignInButton.backgroundColor = plivoColor.withAlphaComponent(0.6)
        self.plivoSignInButton.isEnabled = false
        
        self.twilioSignInButton.backgroundColor = UIColor.red.withAlphaComponent(0.6)
        self.twilioSignInButton.isEnabled = false
    }
    
    private func enableLogin() {
        self.plivoSignInButton.backgroundColor = plivoColor
        self.plivoSignInButton.isEnabled = true
        
        self.twilioSignInButton.backgroundColor = UIColor.red
        self.twilioSignInButton.isEnabled = true
    }
    
    private func doPlivoLogin(userName : String,password : String) {
        self.disableLogin()
        showActivityIndicator()
        SIPManager.sharedInstance.loginForPlivo(withUserName: userName, andPassword: password)
    }
    
    private func openMainController() {
        AppDelegate.shared.voipRegistration()
        
        let dialPadController = DialPadViewController.storyBoardController()
        self.present(dialPadController, animated: true, completion: nil)
    }
    
    // MARK: - Action methods
    
    /**
     * save the user name and open the landing screen
     */
    
    @IBAction func twilioSignInButtonAction(_ sender: Any) {
        if let name = self.twilioUsername.text,!name.isEmpty {
            UserDefaultManager.shared.set(value: AppUtility.getUserNameWithoutDomain(name), forKey: .twilioIdentity)
            openMainController()
        } else {
            self.showAlert(title : NSLocalizedString("Error!", comment: ""),message : NSLocalizedString("Username can't be empty.", comment: ""))
        }
    }
    @IBAction func signInButtonAction(_ sender: Any) {
        if let name = self.plivoUserNameField.text,!name.isEmpty,let password = self.plivoPasswordField.text,!password.isEmpty {
            self.doPlivoLogin(userName : AppUtility.getUserNameWithoutDomain(name),password : password)
        } else {
            self.showAlert(title : NSLocalizedString("Error!", comment: ""),message : NSLocalizedString("Username and Password can't be empty.", comment: ""))
        }
    }
    
    @objc
    private func keyboardWillAppear(_ note: Notification) {
        if self.plivoUserNameField.isFirstResponder,let indexPath = self.indexPath(forView: self.plivoUserNameField) {
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        } else if self.plivoPasswordField.isFirstResponder,let indexPath = self.indexPath(forView: self.plivoPasswordField) {
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        } else if self.twilioUsername.isFirstResponder,let indexPath = self.indexPath(forView: self.twilioUsername) {
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    @objc
    private func keyboardWillHideNotification(_ note: Notification) {
        
    }
}
// MARK: - UITextFieldDelegate
extension LoginViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Plivo delegate
extension LoginViewController : PlivoEndpointDelegate  {
    
    /**
     *
     * Trigger when login successfully made.
     *
     */
    func onLogin() {
        Logger.logDebug(tag: "LoginViewController", message: "onLogin")
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.enableLogin()
            strongSelf.hideActivityIndicator()
            UserDefaultManager.shared.set(value: AppUtility.getUserNameWithoutDomain(strongSelf.plivoUserNameField.text ?? ""), forKey: .plivoUsername)
            UserDefaultManager.shared.set(value: strongSelf.plivoPasswordField.text ?? "", forKey: .plivoPassword)
            
            strongSelf.plivoSignInButton.setTitle(NSLocalizedString("Plivo Logged In", comment: ""), for: .normal)
            strongSelf.plivoSignInButton.backgroundColor = UIColor.clear
            strongSelf.plivoSignInButton.setTitleColor(UIColor.gray, for: .normal)
            strongSelf.plivoSignInButton.isEnabled = false
        }
    }
    
    /**
     *
     * Trigger when login failed
     *
     */
    func onLoginFailed() {
        Logger.logDebug(tag: "LoginViewController", message: "onLoginFailed")
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.enableLogin()
            strongSelf.hideActivityIndicator()
            
            strongSelf.showAlert(title: NSLocalizedString("Login Failed", comment: ""), message: NSLocalizedString("Please check your username and password", comment: ""))
        }
    }
}

