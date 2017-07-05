//
//  APIManager.swift
//  PollSample
//
//  Created by Arjun P A on 13/02/17.
//  Copyright © 2017 Arjun P A. All rights reserved.
//

import Foundation
import UIKit


public class PolltypeSessionManager:NSObject{
    
    static let sharedSession:PolltypeSessionManager = PolltypeSessionManager.init()
    
    var session:URLSession
    var configuration:URLSessionConfiguration
    
    override init() {
        
        configuration = URLSessionConfiguration.default
        configuration.httpMaximumConnectionsPerHost = 1
        self.session = URLSession.init(configuration: configuration)
        super.init()
    }
    
    
    
}

public class APIManager: NSObject {
    
    struct ParseConstants{
        static let loggedInVoted:String = "logged-in-voted"
        static let always:String = "always"
    }
    
    
    var publisherBaseURL:String{
        
        var baseURL = Polltype.shared.hostURl!
        
        if baseURL.hasSuffix("/"){
            baseURL = (baseURL as NSString).deletingLastPathComponent as String
        }
        baseURL = baseURL.appendingFormat("/")
        return baseURL
    }
    
    static var BASEURL:String{
        get{
            var baseURL = Polltype.shared.hostURl!
            if baseURL.hasSuffix("/"){
                baseURL = (baseURL as NSString).deletingLastPathComponent as String
            }
            
            baseURL = baseURL.appendingFormat("/")
            return baseURL
        }
    }
    
    
    fileprivate var pendingPolls:Array<Int> = []
    
    fileprivate var fetchedPolls:Array<Int> = []
    
    internal override init() {
        
    }
    
    
    
    internal func isFetchingPoll(_ forID:Int) -> Bool{
        if pendingPolls.contains(forID){
            return true
        }
        
        return false
    }
    
    internal func isFetchedPoll(_ forID:Int) -> Bool{
        if fetchedPolls.contains(forID){
            return true
        }
        
        return false
    }
    
    
    func fetchAblyToken(_ completion:@escaping (_ token:String?, _ error:Error?) -> Void){
        
        PolltypeSessionManager.sharedSession.session.dataTask(with: (URL.init(string: APIManager.BASEURL + "api/ably-token"))!) { (data, response, error) in
            if let someError = error{
                return completion(nil, someError)
            }
            else{
                do{
                    if let someData = data{
                        if let jsonDcit = try JSONSerialization.jsonObject(with: someData, options: .allowFragments) as? [String:AnyObject]{
                            if let token_str = jsonDcit["token"] as? String{
                                
                                let expression = Constants.kExpressions.ablyKeyCheck
                                let prediciate = NSPredicate.init(format: "SELF MATCHES %@", expression)
                                
                                if !prediciate.evaluate(with: token_str){
                                    completion(nil, NSError.init(domain: "invalid token", code: 1004, userInfo: nil))
                                }
                                else {
                                    completion(token_str, nil)
                                }
                            }
                        }
                        
                    }
                    else{
                        completion(nil, NSError.init(domain: "Null data", code: 1003, userInfo: nil))
                    }
                }
                catch let jsonError{
                    print(jsonError.localizedDescription)
                }
            }
            }.resume()
        
    }
    
    func validateToken(_ tokenStr:String){
        
    }
    
    
    internal func fetchPoll(_ pollID:Int, completion:@escaping (_ poll:Poll?, _ error:Error?) -> Void){
        
        //        if isFetchingPoll(pollID) || isFetchedPoll(pollID){
        //            return
        //        }
        
        self.pendingPolls.append(pollID)
        
        PolltypeSessionManager.sharedSession.session.dataTask(with: URL.init(string: APIManager.BASEURL + "api/polls/" + "\(pollID)")!) { (data, response, error) in
            if let someError = error{
                if let containsIndex = self.pendingPolls.index(of: pollID){
                    self.pendingPolls.remove(at: containsIndex)
                }
                completion(nil, someError)
            }
            else{
                
                
                if ((response as? HTTPURLResponse)?.statusCode)! < 200 || ((response as? HTTPURLResponse)?.statusCode)! >= 300{
                    if let containsIndex = self.pendingPolls.index(of: pollID){
                        self.pendingPolls.remove(at: containsIndex)
                    }
                    completion(nil, NSError.init(domain: "POLL_NOT_FOUND", code: 404, userInfo: ["pollID":pollID]))
                    return
                }
                
                do{
                    
                    let parsedObject = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    
                    self.startParse(parsedObject, completion: { (poll, error) in
                        
                        if poll?.id == nil{
                            poll?.id = pollID
                        }
                        
                        if let containsIndex = self.pendingPolls.index(of: poll?.id ?? 0){
                            self.pendingPolls.remove(at: containsIndex)
                        }
                        
                        guard let _ = poll?.id else{
                            completion(nil, NSError.init(domain: "POLL_NOT_FOUND", code: 404, userInfo: ["pollID":pollID]))
                            return
                        }
                        
                        self.fetchedPolls.append(poll!.id)
                        completion(poll,error)
                    })
                }
                catch{
                    if let containsIndex = self.pendingPolls.index(of: pollID){
                        self.pendingPolls.remove(at: containsIndex)
                    }
                    completion(nil, error)
                }
            }
            }.resume()
        
        
    }
    
    internal func vote(_ poll:Poll,storyURL:URL?,opinionIndex:Int, completion:@escaping (_ poll:Poll?, _ error:Error?) -> Void){
        let urlString = APIManager.BASEURL + "api" + "/polls/" + "\(poll.id!)/votes"
        
        let mutableURLRequest = NSMutableURLRequest.init(url: URL.init(string: urlString)! as URL)
        
        mutableURLRequest.httpMethod = "POST"
        
        var parameters:Dictionary<String, Any> = ["vote":["opinion-id":poll.opinions[opinionIndex].id]]
        if let storyURLPresent = storyURL{
            parameters["url"] = storyURLPresent.absoluteString as AnyObject?
        }
        mutableURLRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //      mutableURLRequest.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options:[])
        mutableURLRequest.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        // NSURLSession.sharedSession().dataTask(with: mutableURLRequest as URLRequest) { (data, response, error) in
        //  PolltypeSessionManager.sharedSession.session.dataTaskWithRequest(mutableURLRequest) { (data, response, error) in
        URLSession.shared.dataTask(with: mutableURLRequest as URLRequest) { (data, response, error) in
            
            
            
            if let someError = error{
                completion(nil, someError)
            }
            else{
                
                do {
                    if let unwrappedData = data {
                        
                        let jsonDictionaries = try JSONSerialization.jsonObject(with: unwrappedData, options: .allowFragments) as! [String: AnyObject]
                        
                        self.parsePollTypeResult(poll, dictionary: jsonDictionaries, completion: { (refactoredPoll) in
                            
                            completion(refactoredPoll, nil)
                        })
                    }
                    
                } catch let jsonError {
                    
                    completion(nil,jsonError)
                }
                
            }
            }.resume()
    }
    
    func parsePollTypeResult(_ poll:Poll,dictionary:[String: AnyObject], completion:(Poll) -> Void){
        
        if let meStructure =  dictionary["me"] as? [String:AnyObject]{
            
            if let hasAccount = meStructure["has-account"] as? NSNumber{
                poll.hasAccount = hasAccount.boolValue
            }
            
            if let qlitics = meStructure["has-qlitics"] as? NSNumber{
                poll.hasQlitics = qlitics.boolValue
            }
        }
        
        if let resultsStructure = dictionary["results"] as? [String:AnyObject]{
            if let opinions = resultsStructure["opinions"] as? [[String:AnyObject]]{
                
                var opinionArray:[Opinion] = []
                
                for opinion in opinions{
                    let opiniond = Opinion()
                    if let id = opinion["id"] as? NSNumber{
                        opiniond.id = id.intValue
                    }
                    
                    if let text = opinion["text"] as? String{
                        opiniond.title = text
                    }
                    
                    if let percentVotes = opinion["percentage-votes"] as? NSNumber{
                        opiniond.percentVotes = percentVotes.intValue
                    }
                    opinionArray.append(opiniond)
                }
                
                poll.opinions = opinionArray
                
                
            }
            if let votedOnDict = resultsStructure["voted-on"] as? [String:AnyObject]{
                if let votedOnID = votedOnDict["id"] as? NSNumber{
                    poll.votedOn = votedOnID.intValue
                }
                let votedOn = VotedOn.init()
                votedOn.id = poll.votedOn
                
                if let votedOnText = votedOnDict["text"] as? String{
                    votedOn.text = votedOnText
                }
                
                if let percentVotes = votedOnDict["percentage-votes"] as? NSNumber{
                    votedOn.percentVotes = percentVotes.intValue
                }
                
                if poll.votedOn != nil{
                    poll.opinions = poll.opinions.map({ (opinion) -> Opinion in
                        if opinion.id == poll.votedOn{
                            if votedOn.percentVotes != 0{
                                opinion.percentVotes = votedOn.percentVotes
                            }
                        }
                        return opinion
                    })
                }
                
                poll.votedOnModel = votedOn
            }
            completion(poll)
            
        }
    }
    
    
    internal func voteViews(_ pollID:Int){
        let urlString = APIManager.BASEURL + "api" + "/polls/" + "\(pollID)/views"
        let mutableURLRequest = NSMutableURLRequest.init(url: URL.init(string: urlString)! as URL)
        mutableURLRequest.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: mutableURLRequest as URLRequest) { (data, response, error) in
            do {
                if let unwrappedData = data {
                    
                    let _ = try JSONSerialization.jsonObject( with: unwrappedData, options: .allowFragments) as? [String: AnyObject]
                    
                    
                }
                
            } catch let jsonError {
                print(jsonError.localizedDescription)
            }
            
            
            }.resume()
    }
    
    internal func voteIntend(_ pollID:Int,opinionID:Int,completion:((_ status:Int?, _ error:Error?, _ jsonData:[String:AnyObject]?) -> Void)? = nil){
        let urlString = APIManager.BASEURL + "api" + "/polls/" + "\(pollID)/intentions"
        
        let url = NSMutableURLRequest(url: URL(string: urlString)! as URL)
        
        url.httpMethod = "POST"
        let parameters = ["intention":["opinion-id":opinionID]]
        
        url.addValue("application/json", forHTTPHeaderField: "Content-Type")
        url.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options:[])
        
        URLSession.shared.dataTask(with: url as URLRequest) { (data, response, error) in
            
            if error != nil {
                if let someCompletion = completion{
                    someCompletion((response as? HTTPURLResponse)?.statusCode, error, nil)
                }
                return
            }
            
            do {
                if let unwrappedData = data {
                    
                    let jsonDictionaries = try JSONSerialization.jsonObject( with: unwrappedData, options: .allowFragments) as? [String: AnyObject]
                    
                    DispatchQueue.main.async {
                        print(jsonDictionaries ?? "")
                        
                        if let someCompletion = completion{
                            someCompletion((response as? HTTPURLResponse)?.statusCode, nil, jsonDictionaries)
                        }
                    }
                }
                
            } catch let jsonError {
                if let someCompletion = completion{
                    
                    someCompletion((response as? HTTPURLResponse)?.statusCode, jsonError, nil)
                }
            }
            
            }.resume()
        
    }
    
    
    
    
    
    
    
    func startParse(_ data:Any,completion:(Poll?, Error?) -> Void){
        
        if let dataJson = data as? [String:AnyObject]{
            
            let pollModel = Poll()
            if let me = (dataJson["me"] as? [String:AnyObject]){
                if let hasAccountNumber = me["has-account"] as? NSNumber{
                    pollModel.hasAccount = hasAccountNumber.boolValue
                }
                
                if let qlicticsNumber = me["has-qlitics"] as? NSNumber{
                    pollModel.hasQlitics = qlicticsNumber.boolValue
                }
            }
            
            if let poll = (dataJson["poll"] as? [String:AnyObject]){
                
                if let pollURL = poll["url"] as? String{
                    pollModel.polltypeURL = pollURL
                }
                
                if let pollID = poll["id"] as? NSNumber{
                    pollModel.id = pollID.intValue
                }
                
                if let topic = poll["topic"] as? String{
                    pollModel.question = topic
                }
                
                if let description = poll["description"] as? String{
                    pollModel.pollDescription  = description
                }
                
                if let votedOnDict = poll["voted-on"] as? [String:AnyObject]{
                    if let votedOnID = votedOnDict["id"] as? NSNumber{
                        pollModel.votedOn = votedOnID.intValue
                    }
                    let votedOn = VotedOn.init()
                    votedOn.id = pollModel.votedOn
                    
                    if let votedOnText = votedOnDict["text"] as? String{
                        votedOn.text = votedOnText
                    }
                    
                    if let percentVotes = votedOnDict["percentage-votes"] as? NSNumber{
                        votedOn.percentVotes = percentVotes.intValue
                    }
                    pollModel.votedOnModel = votedOn
                }
                
                if let settings = poll["settings"] as? [String:AnyObject]{
                    if let changeVoteEnabled = settings["change-vote?"] as? NSNumber{
                        pollModel.isChangeVoteEnabled = changeVoteEnabled.boolValue
                    }
                    
                    if let showResults = settings["show-results"] as? String{
                        if showResults == APIManager.ParseConstants.always{
                            pollModel.showResult = Poll.ShowResults.always
                        }
                        else if showResults == APIManager.ParseConstants.loggedInVoted{
                            pollModel.showResult = Poll.ShowResults.loggedInVoted
                        }
                        
                        
                    }
                    
                    if let anonymousVotingEnabled = settings["anonymous-voting?"] as? NSNumber{
                        pollModel.isAnonymousVoteEnabled = anonymousVotingEnabled.boolValue
                    }
                    
                    if let showDefaultHeroImage = settings["show-default-hero-image-in-embed"] as? NSNumber{
                        pollModel.showDefaultHeroImage = showDefaultHeroImage.boolValue
                    }
                    
                }
                
                if let opinions = poll["opinions"] as? [[String:AnyObject]]{
                    
                    var opinionArray:[Opinion] = []
                    
                    for opinion in opinions{
                        let opiniond = Opinion()
                        if let id = opinion["id"] as? NSNumber{
                            opiniond.id = id.intValue
                        }
                        
                        if let text = opinion["text"] as? String{
                            opiniond.title = text
                        }
                        
                        if let percentVotes = opinion["percentage-votes"] as? NSNumber{
                            opiniond.percentVotes = percentVotes.intValue
                        }
                        opinionArray.append(opiniond)
                    }
                    
                    pollModel.opinions = opinionArray
                    
                }
                
                
                if let heroImage = poll["hero-image"] as? [String:AnyObject]{
                    
                    if let s3Key = heroImage["s3-key"] as? String{
                        pollModel.heroImageS3Key = s3Key
                        if let metadata = heroImage["metadata"] as? [String:AnyObject]{
                            
                            let metadataImage:ImageMetaData = ImageMetaData.init()
                            
                            if let width = metadata["width"] as? NSNumber{
                                metadataImage.width = width.intValue as NSNumber?
                            }
                            
                            if let height = metadata["height"] as? NSNumber{
                                metadataImage.height = height.intValue as NSNumber?
                            }
                            
                            
                            if let focusPoints = metadata["focus-point"] as? [NSNumber]{
                                var focusPointArray = [Int]()
                                
                                for point in focusPoints{
                                    focusPointArray.append(point.intValue)
                                }
                                
                                metadataImage.focus_point = focusPointArray as [NSNumber]?
                            }
                            
                            
                            
                            pollModel.heroImageMetadata = metadataImage
                        }
                        if let defaultHeroImageIsPresent = heroImage["default?"] as? NSNumber{
                            pollModel.isDefaultHeroImage = defaultHeroImageIsPresent.boolValue
                        }
                    }
                    
                }
                
                if let metadata = poll["metadata"] as? [String:AnyObject]{
                    if let options = metadata["options"] as? [String:AnyObject]{
                        
                        if let showResults = options["always-show-results"] as? NSNumber{
                            pollModel.alwaysShowResult = showResults.boolValue
                        }
                    }
                }
            }
            
            completion(pollModel, nil)
        }
        else{
            let error = NSError.init(domain: "Root Structure not defined", code: 24, userInfo: nil)
            completion(nil,error as Error)
            
        }
    }
}
