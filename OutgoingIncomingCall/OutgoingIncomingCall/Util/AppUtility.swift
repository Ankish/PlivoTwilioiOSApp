//
//  AppUtility.swift
//  OutgoingIncomingCall
//
//  Created by Plivo on 12/8/18.
//  Copyright © 2018 Plivo. All rights reserved.
//

import Foundation
import SystemConfiguration

/**
 *
 * AppUtility
 * To Lock Orientation for each screen
 *
 */
struct AppUtility {
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    
    static func isNetworkAvailable() -> Bool {
        guard let flags = getFlags() else { return false }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }

    static func getFlags() -> SCNetworkReachabilityFlags? {
        guard let reachability = ipv4Reachability() ?? ipv6Reachability() else {
            return nil
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(reachability, &flags) {
            return nil
        }
        
        return flags
    }
    
    static func ipv6Reachability() -> SCNetworkReachability? {
        var zeroAddress = sockaddr_in6()
        zeroAddress.sin6_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin6_family = sa_family_t(AF_INET6)
        return withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        })
    }
    
    static func ipv4Reachability() -> SCNetworkReachability? {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        return withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        })
    }
    
    /*
     * remove any sip type/domain related
     * information from username
     */
    static func getUserNameWithoutDomain(_ userName : String) -> String {
        var userNameArray = userName.components(separatedBy: "@")
        if (userNameArray.count > 0) {
            let modifiedName = userNameArray[0]
            Logger.logDebug(tag: "AppUtility", message: "found @ in username modified username \(modifiedName)")
            return modifiedName
        } else {
            return userName
        }
    }
    
}

enum SipType : Int {
    case plivo = 0
    case twilio
}
