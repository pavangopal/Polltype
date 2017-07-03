//
//  Poll.swift
//  Pods
//
//  Created by Pavan Gopal on 6/28/17.
//
//

import Foundation

public class Poll:NSObject{
    
    public struct Constants{
        
        static var polltypeHost:NSURL = NSURL.init(string: "https://www.polltype.com/")!
    }
    
    public var hasAccount:Bool = false
    public var hasQlitics:Bool = false
    public var pollDescription:String?
    public var votedOn:Int?
    public var alwaysShowResult:Bool = false
    
    public var id:Int!
    public var question:String = ""
    
    public var opinions:[Opinion] = []
    public var heroImageS3Key:String?
    public var heroImageMetadata:ImageMetaData?
    public var isChangeVoteEnabled:Bool = true
    public var isAnonymousVoteEnabled:Bool = false
    public var votedOnModel:VotedOn?
    public var showDefaultHeroImage:Bool = false
    public var isDefaultHeroImage:Bool = false
    public var polltypeURL:String = ""
    
    public enum ShowResults:String{
        case always = "always"
        case loggedInVoted = "logged-in-voted"
        
    }
    
   open var showResult:ShowResults = ShowResults.loggedInVoted
    
    
   open func shouldShowHeroImage() -> Bool{
        if self.heroImageS3Key == nil{
            return false
        }
        
        if self.showDefaultHeroImage{
            
            return true
        }
        
        if self.isDefaultHeroImage{
            return false
        }
        
        return true
    }
    
    
    func isPollDataStale(newPoll:Poll) -> Bool{
        
        if opinions.count != newPoll.opinions.count{
            return true
        }
        
        for (index, opinion) in opinions.enumerated(){
            if opinion.percentVotes != newPoll.opinions[index].percentVotes{
                return true
            }
            if opinion.title != newPoll.opinions[index].title{
                return true
            }
            
            if opinion.id != newPoll.opinions[index].id{
                return true
            }
        }
        return false
    }
}

public class Opinion: NSObject {
    
    public var title:String!
    public var id:Int!
    public var percentVotes:Int = 0
}

public class VotedOn:NSObject{
    public var text:String!
    public var id:Int!
    public var percentVotes:Int = 0
}

public class ImageMetaData:NSObject {
    
    public var width: NSNumber?
    public var height: NSNumber?
    public var focus_point: [NSNumber]?
    
}


