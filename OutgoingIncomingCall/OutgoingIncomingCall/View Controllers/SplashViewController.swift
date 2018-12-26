//
//  SplashViewController.swift
//  OutgoingIncomingCall
//
//  Created by Plivo on 12/13/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import UIKit
import PlivoVoiceKit

class SplashViewController: UIViewController {

    private let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(activityIndicator)
        activityIndicator.color = UIColor.black
        
        SIPManager.sharedInstance.setPlivoDelegate(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.activityIndicator.center = self.view.center
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let username = UserDefaultManager.shared.value(forKey: .plivoUsername) as? String,!username.isEmpty,let password = UserDefaultManager.shared.value(forKey: .plivoPassword) as? String,!password.isEmpty,let twiloIdentity = UserDefaultManager.shared.value(forKey: .twilioIdentity) as? String,!twiloIdentity.isEmpty {
            self.showActivityIndicator()
            SIPManager.sharedInstance.loginForPlivo(withUserName: username, andPassword: password)
        } else {
            openLoginController()
        }
        
    }
    
    private func openLoginController() {
        let loginController = LoginViewController.storyBoardController()
        self.present(loginController, animated: true, completion: nil)
    }
    
    func showActivityIndicator() {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }
    
    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }

}
// MARK: - Plivo delegate
extension SplashViewController : PlivoEndpointDelegate  {
    
    /**
     *
     * Trigger when login successfully made.
     *
     */
    func onLogin() {
        Logger.logDebug(tag: "SplashViewController", message: "onLogin")
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.hideActivityIndicator()
            let dialPadController = DialPadViewController.storyBoardController()
            strongSelf.present(dialPadController, animated: true, completion: nil)
            
            AppDelegate.shared.voipRegistration()
        }
    }
    
    /**
     *
     * Trigger when login failed
     *
     */
    func onLoginFailed() {
        Logger.logDebug(tag: "SplashViewController", message: "onLoginFailed")
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.hideActivityIndicator()
            UserDefaultManager.shared.set(value: "", forKey: .plivoUsername)
            UserDefaultManager.shared.set(value: "", forKey: .plivoPassword)
            
            strongSelf.showAlert(title: NSLocalizedString("Login Failed", comment: ""), message: NSLocalizedString("Please check your username and password", comment: ""),okAction : { (_) in
                strongSelf.openLoginController()
            })
        }
    }
}

