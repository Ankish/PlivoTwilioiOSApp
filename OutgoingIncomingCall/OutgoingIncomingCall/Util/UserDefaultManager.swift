//
//  DefaultsManager.swift
//  OutgoingIncomingCall
//
//  Created by Plivo on 12/7/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import Foundation

enum DefaultsKey : String {
    case plivoUsername = "plivoUsername"
    case plivoPassword = "plivoPassword"
    case twilioIdentity = "twilioIdentity"
}

/**
 *
 * UserDefaultManager
 * Stores and retrive the value from standar user defaults
 *
 */
class UserDefaultManager {
    public static let shared = UserDefaultManager()
    
    private let defaults = UserDefaults.standard
    
    func value(forKey: DefaultsKey) -> Any? {
        return defaults.value(forKey: forKey.rawValue)
    }
    
    func set(value: Any,forKey: DefaultsKey) {
        defaults.set(value, forKey: forKey.rawValue)
        defaults.synchronize()
    }

    func removeObject(forKey: DefaultsKey) {
        defaults.removeObject(forKey: forKey.rawValue)
        defaults.synchronize()
    }
}

