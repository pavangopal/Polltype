//
//  PolltypeCellDelegate.swift
//  Polltype
//
//  Created by Pavan Gopal on 7/5/17.
//  Copyright © 2017 Pavan Gopal. All rights reserved.
//

import Foundation

public protocol PolltypeCellDelegate:class {
    
    func didClickOnVote(_ poll:Poll, opinionIndex:Int, view:PolltypeView)
    func didClickOnShare(_ poll:Poll,view:UIButton)
    func didTapOnPolltype(_ poll:Poll,view:PolltypeView)
    func didClickOnLogin(_ poll:Poll, view:PolltypeView)
    func didViewPoll(_ pollID:Int)
    
}
