//
//  Polltype.swift
//  Polltype
//
//  Created by Pavan Gopal on 6/30/17.
//  Copyright © 2017 Pavan Gopal. All rights reserved.
//

import Foundation
import Ably

protocol PolltypeDelegate {
    func shouldReloadUIForPollId(pollId:Int,updatedPoll:Poll?)
}

open class Polltype : NSObject{
    
   open static let shared = Polltype()
    
    fileprivate var _api:APIManager?
    
    var parentView:UIView?
    
    var polls:[Int:Poll] = [:]
    
    var api:APIManager{
        get{
            if _api == nil{
                _api = APIManager.init()
            }
            return _api!
        }
        set{
            _api = newValue
        }
    }
    
    
    var hostURl : String!
    
    var ablyToken:String?
    
    var pollChannel: ARTRealtimeChannel!
    var ablyManager:AblyManager!
    
    var pollIndexPathMapping:[Int:IndexPath] = [:]
    typealias LOGIN_COMPLETION = () -> ()
    var loginCompletion:LOGIN_COMPLETION?
    
    var _loginWebView:UIWebView?
    
    var loginWebView:UIWebView?{
        get{
            if _loginWebView == nil{
                _loginWebView = UIWebView.init()
                _loginWebView?.translatesAutoresizingMaskIntoConstraints = false
            }
            return _loginWebView!
        }
        set{
            _loginWebView = nil
        }
    }
    
    private var _ablyParseManager:AblyParseManager?
    var ablyParseManager:AblyParseManager{
        get{
            if _ablyParseManager == nil{
                _ablyParseManager = AblyParseManager.init()
            }
            return _ablyParseManager!
        }
        set{
            _ablyParseManager = newValue
        }
    }
    
    var PollTypeDelegate:PolltypeDelegate?
    
    private override init(){}
    
    public func configure(withHostUrl url:String){
        
        self.hostURl = url
    }
    
    
    
   public func getPoll(withId id:Int, onSucess:@escaping (Int,Poll?)->(), onError:@escaping (String?)->()){
        
        api.fetchPoll(id) {(poll, error) in
            
            if let unwrappedError = error{
                onError(unwrappedError.localizedDescription)
            }
            else{
                self.pollChannel = self.ablyManager.client.channels.get("polltype-clients:results-\(id)")
                self.watchPollChange(channel: self.pollChannel)
                onSucess(id, poll)
                
            }
        }
    }
    
  //Step 1: Call in viewdidLoad()
    
  public  func generateAblyToken(){
        
        self.api.fetchAblyToken({[weak self] (token, error) in
            
            guard let weakSelf = self else {return}
            
            if let someError = error{
                
                print(someError.localizedDescription)
            }
            else{
                
                print("TOKEN: \(token)")
                
                if let someTOken = token{
                    
                    weakSelf.ablyToken = someTOken
                    
                    weakSelf.ablyManager = AblyManager.init(key: someTOken)
                    self?.ablyManager = AblyManager.init(key: someTOken)
                }
            }
        })
    }
    
    func watchPollChange(channel:ARTRealtimeChannel){
        
        channel.attach()
        
        channel.subscribe({ (message) in
            
            guard let messageData = message.data else {return}
            do{
                let data = try JSONSerialization.data(withJSONObject: messageData as! NSDictionary, options: .prettyPrinted)
                print("ABLY JSON: \(String.init(data: data, encoding: String.Encoding.utf8))")
                
                self.ablyParseManager.startParse(message.data as? [String:AnyObject], completion: {[weak self] (poll) in
                    
                    guard let weakSelf = self else{ return }
                    
                    if let somePoll = poll{
                        
                        var shouldReload = false
                        
                        for (_,poll) in weakSelf.polls{
                            
                            shouldReload =  poll.isPollDataStale(newPoll: somePoll)
                            
                            if !shouldReload{
                                return
                            }else{
                                self?.polls[somePoll.id]?.opinions = somePoll.opinions
                                
                                break
                            }
                        }
                        
                        if shouldReload{
                            weakSelf.PollTypeDelegate?.shouldReloadUIForPollId(pollId: somePoll.id,updatedPoll: somePoll)
                        }
                    }
                })
            }catch{
                
                print("Error caught")
                
            }
            
        })
        
        
    }
}

extension Polltype:PolltypeCellDelegate{
    
    
    func shouldPerformReloadForPendingPoll(_ poll: Poll) -> Bool {
        return false
    }
    
    public func didViewPoll(_ pollID: Int) {
        
    }
    
    public func didClickOnLogin(_ poll: Poll, cell: PolltypeCell) {
        
    }
    
    public func didTapOnPolltype(_ poll:Poll){
        
    }
    
    public func didClickOnShare(_ poll: Poll) {
        
    }
    
    public func didClickOnVote(_ poll: Poll, opinionIndex: Int, cell: PolltypeCell) {
        print("did enter here")
        
        api.voteIntend(poll.id, opinionID: poll.opinions[opinionIndex].id)
        
        if poll.hasAccount{
            
            self.vote(poll, opinionIndex: opinionIndex, cell: cell)
        }
        else{
            DispatchQueue.main.async(execute: {
                self.showWebView(cell)
            })
            
            self.loginCompletion = {
                self.closeWebview(self.loginWebView!)
                self.vote(poll, opinionIndex: opinionIndex, cell: cell)
            }
        }
    }
    
    func vote(_ poll:Poll, opinionIndex:Int, cell: PolltypeCell){
        
        api.vote(poll,storyURL: nil,opinionIndex: opinionIndex) { (polld, error) in
            
            
            if let _ = error{
                return
            }
            
            self.polls[(polld?.id)!] = polld
            
            self.polls[(polld?.id)!]?.hasAccount = polld?.hasAccount ?? false
            
            
            self.PollTypeDelegate?.shouldReloadUIForPollId(pollId: (polld?.id)!,updatedPoll: polld)
            
        }
    }
    
}

extension Polltype:UIWebViewDelegate{
    
    public func showWebView(_ cell: PolltypeCell?){
        loginWebView!.removeFromSuperview()
        self.parentView?.addSubview(self.loginWebView!)
        self.parentView?.bringSubview(toFront: self.loginWebView!)
        self.loginWebView?.delegate = self
        
        
        loginWebView?.topAnchor.constraint(equalTo: (self.parentView?.topAnchor)!).isActive = true
        loginWebView?.bottomAnchor.constraint(equalTo: (self.parentView?.bottomAnchor)!).isActive = true
        loginWebView?.leadingAnchor.constraint(equalTo: (self.parentView?.leadingAnchor)!).isActive = true
        loginWebView?.trailingAnchor.constraint(equalTo: (self.parentView?.trailingAnchor)!, constant: 0).isActive = true
        
        let closeButton = UIButton.init(type: .custom)
        closeButton.tag = 20
        closeButton.backgroundColor = UIColor.darkGray
        closeButton.setTitle("X", for: UIControlState())
        closeButton.setTitleColor(UIColor.lightText, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(ViewController.closeWebview(_:)), for: .touchUpInside)
        self.loginWebView?.addSubview(closeButton)
        self.loginWebView?.bringSubview(toFront: closeButton)
        closeButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        closeButton.trailingAnchor.constraint(equalTo: (self.parentView?.trailingAnchor)!, constant: -20).isActive = true
        closeButton.topAnchor.constraint(equalTo: (self.loginWebView?.topAnchor)!, constant: 20).isActive = true
        
        self.loginWebView?.loadRequest(URLRequest.init(url: URL.init(string: APIManager.BASEURL + "login")!))
    }
    
    func closeWebview(_ sender:UIWebView){
        
        self.loginWebView?.removeFromSuperview()
        self.loginWebView?.delegate = nil
        self.loginWebView = nil
    }
    
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        
        return true
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        
        guard let url = webView.request?.url?.absoluteString.components(separatedBy: "/")else {return}
        
        url.forEach({ (data) in
            print(data)
            if (data == "me#_=_") || (data ==  "me"){
                
                print("LoggedIn")
                
                if let someCompletion = loginCompletion{
                    someCompletion()
                }
            }
            
        })
    }
    
}
