//
//  AblyManager.swift
//  QuintypeSDK
//
//  Created by Arjun P A on 20/02/17.
//  Copyright © 2017 Quintype. All rights reserved.
//

import Foundation
import Ably

public class AblyManager: NSObject {
    
    var client:ARTRealtime
    var ablyClientOptions:ARTClientOptions!
    
    init(key:String) {
        
        ablyClientOptions = ARTClientOptions()
        ablyClientOptions.key = key
        ablyClientOptions.logLevel = .error
        
        self.client = ARTRealtime.init(options: ablyClientOptions)
        
        self.client.connection.on { (state) in
            if state == nil{
                print("state is nil")
            }
            
            
            let stateChange = state!
            switch stateChange.current {
            case .initialized:
                print("initialized")
                break
            case .connecting:
                print("connecting")
                break
            case .connected:
                print("connected!")
                break
            case .failed:
                print("failed! \(stateChange.reason)")
                break
            case .disconnected:
                print("disconnected")
                break
            case .suspended:
                print("suspended")
                break
            case .closing:
                print("closing")
                break
            case .closed:
                print("closed")
                break
            }
            
        }
        
        super.init()
    }
    
    
    
}
