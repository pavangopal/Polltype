//
//  AblyParseManager.swift
//  QuintypeSDK
//
//  Created by Arjun P A on 20/02/17.
//  Copyright © 2017 Quintype. All rights reserved.
//

import UIKit


class AblyParseManager: NSObject {

    fileprivate var _queue:OperationQueue?
    
    var queue:OperationQueue{
        get{
            if _queue == nil{
            
                _queue = OperationQueue.init()
            }
            return _queue!
        }
        set{
            _queue = newValue
        }
        
        
    }
    
    func startParse(_ dictionary:[String:AnyObject]?,completion:@escaping (Poll?) -> Void){
        self.queue.addOperation {
            if let dict = dictionary{
                if let pollID = dict["id"] as? NSNumber{
                    let polld = Poll()
                    polld.id = pollID.intValue
                    
                    if let opinions = dict["opinions"] as? [[String:AnyObject]]{
                        var opinionArray:[Opinion] = []
                        
                        for opinionDict in opinions{
                            
                            let opinion = Opinion()
                            if let opID = opinionDict["id"] as? NSNumber{
                                opinion.id = opID.intValue
                            }
                            
                            if let textd = opinionDict["text"] as? String{
                                opinion.title = textd
                            }
                            
                            if let percent = opinionDict["percentage-votes"] as? NSNumber{
                                opinion.percentVotes = percent.intValue
                            }
                            
                            opinionArray.append(opinion)
                        }
                        polld.opinions = opinionArray
                        
                        completion(polld)
                    }
                }
            }
        }
    
        
    }
}
