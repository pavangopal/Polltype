//
//  PollTypeThankyou.swift
//  QuintypeSDK
//
//  Created by Arjun P A on 13/03/17.
//  Copyright © 2017 Quintype. All rights reserved.
//

import Foundation
import UIKit

class PollTypeThankyou:UIView{
    
    
    class func instantiateFromNib() -> PollTypeThankyou{
        
        let bundleId = Bundle(identifier: "org.cocoapods.Polltype")
        return UINib.init(nibName: "PollTypeThankyou", bundle: bundleId).instantiate(withOwner: nil, options: nil)[0] as! PollTypeThankyou
    }
    
    func displayVote(_ votePercent:Int){
        if let percentLabel = self.viewWithTag(20) as? UILabel{
            percentLabel.text = "\(votePercent)%"
        }
    }
}
