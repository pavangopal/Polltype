//
//  PolltypeCell.swift
//  Polltype
//
//  Created by Pavan Gopal on 7/3/17.
//  Copyright © 2017 Pavan Gopal. All rights reserved.
//

import UIKit
import Polltype

public protocol PolltypeCellDelegate{
    
    func pollData(poll:Poll)
}

class PolltypeCell: UICollectionViewCell {
    
    
    var pollView:PolltypeView = {
        let view = PolltypeView()
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    var delegate:PolltypeCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpView(){
        
        self.contentView.addSubview(pollView)
        pollView.translatesAutoresizingMaskIntoConstraints = false
        
        pollView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0).isActive = true
        pollView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0).isActive = true
        pollView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 0).isActive = true
        pollView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: 0).isActive = true
        
    }
    
    
    func configure(id:Int){

        Polltype.shared.getPoll(withId: id, onSucess: { (pollId, poll) in
            
                self.pollView.configure(storyElement: poll)
            
                self.delegate?.pollData(poll: poll!)
            
        }) { (errorMessage) in
            print(errorMessage!)
        }
        
    }
    
    
    
    func configure(poll:Poll){
        
        self.pollView.configure(storyElement: poll)
        
    }
    

    
}










