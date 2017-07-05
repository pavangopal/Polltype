//
//  PoweredByPollTypeView.swift
//  QuintypeSDK
//
//  Created by Arjun P A on 20/02/17.
//  Copyright © 2017 Quintype. All rights reserved.
//

import Foundation
import UIKit

class PoweredByPollTypeView:UIView{
    
    
    @IBOutlet weak var logoImageView:UIImageView!
    class func instantiateFromNib() -> PoweredByPollTypeView{
        
        return UINib.init(nibName: "PoweredByPollType", bundle: Bundle(identifier: "org.cocoapods.Polltype")).instantiate(withOwner: nil, options: nil)[0] as! PoweredByPollTypeView
    }
    
}
