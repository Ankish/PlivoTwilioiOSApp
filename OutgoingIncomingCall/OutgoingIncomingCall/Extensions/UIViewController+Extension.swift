//
//  UIViewController+Extension.swift
//  OutgoingIncomingCall
//
//  Created by Plivo on 12/7/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showAlert(title : String,message : String,okAction : ((UIAlertAction)->Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: okAction)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
}
