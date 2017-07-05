//
//  ApiService.swift
//  PollType
//
//  Created by Albin CR on 9/27/16.
//  Copyright © 2016 Albin CR. All rights reserved.
//

import Foundation

class ApiService: NSObject {
    
    static let sharedInstance = ApiService()


    
    //MARK: - get abely token -
    
    func getAbelyApiKey(_ completion:@escaping (Bool)->()){
        
        let baseURL = "https://polltype-api.staging.quintype.io"
        
        fetchFeedForUrlString("GET", urlString: baseURL + "/api/ably-token", parameter: nil) { (status, json) in
            
            if json != nil{
                if let _ = json!["token"]{
                    
                    completion(true)
                    
                }
            }
        }
    }
    
    //MARK: - get polling details -
    
    func fetchPoll(_ pollId:Int,completion: @escaping (Poll) -> ()) {
        
        // var baseURL = self.defaults.stringForKey("pollTypeBaseUrl")!
        let baseURL = "https://polltype-api.staging.quintype.io"
        
        fetchFeedForUrlString("GET",urlString: "\(baseURL)/api/polls/\(pollId)",parameter:nil) { (status, json) in
            
            if status{
                
                if json != nil{
                    self.pollParser(json!, completed: { (data) in
                        completion(data)
                    })
                }
            }
        }
        
    }
    
    //MARK: - post vote -
    
    func vote(_ pollId:Int,parameter:[String:AnyObject]?,completion: @escaping (Poll) -> ()) {
        
        //   var baseURL = self.defaults.stringForKey("pollTypeBaseUrl")!
        
        let baseURL = "https://polltype-api.staging.quintype.io"
        
        fetchFeedForUrlString("POST",urlString: "\(baseURL)/api/polls/\(pollId)/votes",parameter:parameter) { (status, json) in
            
            if status{
                
                self.voteParser(json!) { (data) in
                    completion(data)
                }
                
            }
        }
    }
    
    func voteIntend(_ pollId:Int,parameter:[String:AnyObject]?){
        
        //  var baseURL = self.defaults.stringForKey("pollTypeBaseUrl")!
        let baseURL = "https://polltype-api.staging.quintype.io"
        
        fetchFeedForUrlString("GET",urlString: "\(baseURL)/\(pollId)/intentions",parameter:parameter) { (status, json) in
            
            
            
        }
        
        
    }
    
    //MARK: - API calling function - Private
    
    fileprivate func fetchFeedForUrlString(_ method:String,urlString: String,parameter:[String:AnyObject]?, completion: @escaping (Bool,[String: AnyObject]?) -> ()) {
        var url = URLRequest(url: URL(string: urlString)!)
        
        url.httpMethod = method.capitalized
        
        if let parameter = parameter{
            url.addValue("application/json", forHTTPHeaderField: "Content-Type")
            url.httpBody = try! JSONSerialization.data(withJSONObject: parameter, options:[])
            
        }
        
        let dataTask =  URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                
                completion(true,nil)
                return
            }
            
            do {
                if let unwrappedData = data, let jsonDictionaries = try JSONSerialization.jsonObject(with: unwrappedData, options: .mutableContainers) as? [String: AnyObject] {
                    
                    
                    
                    DispatchQueue.main.async(execute: {
                        
                        
                        completion(true,jsonDictionaries)
                    })
                }
                
            } catch let jsonError {
                print(jsonError.localizedDescription)
            }
        }
        dataTask.resume()
    }
    
    
    //MARK: - for parsing get polling -
    fileprivate func pollParser(_ json:[String: AnyObject], completed:(Poll)->()){
 
    }
    
    //MARK: - for parsing result of voting -
    fileprivate func voteParser(_ json:[String: AnyObject], completed:(Poll)->()){
        let poll = Poll()
        
        if let error = json["message"]{
            print(error)
        }else{
                completed(poll)
        }
    }
    
    fileprivate func cookieDetails(_ response:HTTPURLResponse,fields:[String : String]){
        for cookie in HTTPCookieStorage.shared.cookies! {
            
            print("Cookie Name:\(cookie.name)")
            
        }
    }
}
