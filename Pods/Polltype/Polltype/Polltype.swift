//
//  Polltype.swift
//  Polltype
//
//  Created by Pavan Gopal on 6/30/17.
//  Copyright © 2017 Pavan Gopal. All rights reserved.
//

import Foundation
import Ably

public protocol PolltypeDelegate {
    func shouldReloadUIForPollId(pollId:Int,updatedPoll:Poll?)
    
}

open class Polltype : NSObject{
    
    open static let shared = Polltype()
    
    fileprivate var _api:APIManager?
    
    public var parentViewController:UIViewController?
    
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
    var imageCDN : String!
    var storyUrl : String!
    
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
    
    public var PollTypeDelegate:PolltypeDelegate?
    
    private override init(){}
    
    public func configure(withHostUrl url:String,imageCDN:String,storyUrl:String){
        
        self.hostURl = url
        self.imageCDN = imageCDN
        self.storyUrl = storyUrl
        
        Polltype.shared.generateAblyToken()
        
    }
    
    
    
    public func getPoll(withId id:Int, onSucess:@escaping (Int,Poll?)->(), onError:@escaping (String?)->()){
        
        if self.polls[id] != nil{
            DispatchQueue.main.async {
                onSucess(id, self.polls[id])
            }
        }else{
            
            api.fetchPoll(id) {(poll, error) in
                
                if let unwrappedError = error{
                    onError(unwrappedError.localizedDescription)
                }
                else{
                    DispatchQueue.main.async {
                        if self.ablyToken != nil{
                            
                            self.pollChannel = self.ablyManager.client.channels.get("polltype-clients:results-\(id)")
                            self.watchPollChange(channel: self.pollChannel)
                        }
                        
                        onSucess(id, poll)
                        
                    }
                    
                }
            }
        }
    }
    
    public func loadPollView(id:Int,view:PolltypeView,onSucess:@escaping (Int,Poll?,PolltypeView?)->(), onError:@escaping (String?)->()){
        
        getPoll(withId: id, onSucess: { (pollid, poll) in
            
            DispatchQueue.main.async {
                
                
                if self.pollChannel == nil && self.ablyToken != nil{
                    
                    //                    self.pollChannel = self.ablyManager.client.channels.get("polltype-clients:results-\(id)")
                    //                    self.watchPollChange(channel: self.pollChannel)
                }
                
                self.polls[id] = poll
                
                onSucess(pollid, poll, view)
                
            }
            
        }) { (errorMessage) in
            print(errorMessage)
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
                            
                            DispatchQueue.main.async {
                                weakSelf.PollTypeDelegate?.shouldReloadUIForPollId(pollId: somePoll.id,updatedPoll: self?.polls[somePoll.id])
                            }
                            
                        }
                    }
                })
            }catch{
                
                print("Error caught")
                
            }
            
        })
        
        
    }
}


extension Polltype:UIWebViewDelegate{
    
    public func showWebView(_ cell: PolltypeView?,withUrlRequest:URLRequest?){
        loginWebView!.removeFromSuperview()
        self.parentViewController?.view?.addSubview(self.loginWebView!)
        self.parentViewController?.view?.bringSubview(toFront: self.loginWebView!)
        self.loginWebView?.delegate = self
        
        loginWebView?.topAnchor.constraint(equalTo: (self.parentViewController?.view?.topAnchor)!).isActive = true
        loginWebView?.bottomAnchor.constraint(equalTo: (self.parentViewController?.view?.bottomAnchor)!).isActive = true
        loginWebView?.leadingAnchor.constraint(equalTo: (self.parentViewController?.view?.leadingAnchor)!).isActive = true
        loginWebView?.trailingAnchor.constraint(equalTo: (self.parentViewController?.view?.trailingAnchor)!, constant: 0).isActive = true
        
        let closeButton = UIButton.init(type: .custom)
        closeButton.tag = 20
        closeButton.backgroundColor = UIColor.darkGray
        closeButton.setTitle("X", for: UIControlState())
        closeButton.setTitleColor(UIColor.lightText, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(self.closeWebview(_:)), for: .touchUpInside)
        self.loginWebView?.addSubview(closeButton)
        self.loginWebView?.bringSubview(toFront: closeButton)
        closeButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        closeButton.trailingAnchor.constraint(equalTo: (self.parentViewController?.view?.trailingAnchor)!, constant: -20).isActive = true
        closeButton.topAnchor.constraint(equalTo: (self.loginWebView?.topAnchor)!, constant: 20).isActive = true
        
        self.loginWebView?.loadRequest(withUrlRequest!)
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


extension Polltype:PolltypeCellDelegate{
    
    
    func shouldPerformReloadForPendingPoll(_ poll: Poll) -> Bool {
        return false
    }
    
    public func didViewPoll(_ pollID: Int) {
        
        api.voteViews(pollID)
    }
    
    public func didClickOnLogin(_ poll: Poll, view: PolltypeView) {
        
        DispatchQueue.main.async(execute: {
            self.showWebView(view, withUrlRequest: URLRequest.init(url: URL.init(string: APIManager.BASEURL + "login")!))
        })
        
        self.loginCompletion = {
            self.closeWebview(self.loginWebView!)
            let tempPoll = poll
            tempPoll.hasAccount = true
            
            self.updatePOll(polld: poll)
            
        }
    }
    
    public func didTapOnPolltype(_ poll:Poll,view: PolltypeView){
        
        DispatchQueue.main.async(execute: {
            self.showWebView(view, withUrlRequest: URLRequest.init(url: URL.init(string: poll.polltypeURL) ?? Poll.Constants.polltypeHost))
        })
        
        
    }
    
    public func didClickOnShare(_ poll: Poll,view:UIButton) {
        
        let firstActivityItem : URL = URL(string: storyUrl)!
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [firstActivityItem], applicationActivities: nil)
        
        // This lines is for the popover you need to show in iPad
        activityViewController.popoverPresentationController?.sourceView = view
        
        // This line remove the arrow of the popover to show in iPad
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.unknown
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        // Anything you want to exclude
        activityViewController.excludedActivityTypes = [
            UIActivityType.postToWeibo,
            UIActivityType.print,
            UIActivityType.assignToContact,
            UIActivityType.saveToCameraRoll,
            UIActivityType.addToReadingList,
            UIActivityType.postToFlickr,
            UIActivityType.postToVimeo,
            UIActivityType.postToTencentWeibo,
            UIActivityType.airDrop,
            UIActivityType.copyToPasteboard
        ]
        
        self.parentViewController?.present(activityViewController, animated: true, completion: nil)
        
    }
    
    public func didClickOnVote(_ poll: Poll, opinionIndex: Int, view: PolltypeView) {
        print("did enter here")
        
        api.voteIntend(poll.id, opinionID: poll.opinions[opinionIndex].id)
        
        if poll.hasAccount{
            
            self.vote(poll, opinionIndex: opinionIndex, cell: view)
        }
        else{
            
            DispatchQueue.main.async(execute: {
                self.showWebView(view, withUrlRequest: URLRequest.init(url: URL.init(string: APIManager.BASEURL + "login")!))
                
            })
            
            self.loginCompletion = {
                self.closeWebview(self.loginWebView!)
                self.vote(poll, opinionIndex: opinionIndex, cell: view)
            }
        }
    }
    
    func vote(_ poll:Poll, opinionIndex:Int, cell: PolltypeView){
        
        api.vote(poll,storyURL: nil,opinionIndex: opinionIndex) { (polld, error) in
            
            if let _ = error{
                return
            }
            
            self.polls[(polld?.id)!] = polld
            
            self.polls[(polld?.id)!]?.hasAccount = polld?.hasAccount ?? false
            
            DispatchQueue.main.async {
                self.PollTypeDelegate?.shouldReloadUIForPollId(pollId: (polld?.id)!,updatedPoll: polld)
            }
            
            
        }
    }
    
    func updatePOll(polld:Poll?){
        self.polls[(polld?.id)!] = polld
        
        self.polls[(polld?.id)!]?.hasAccount = polld?.hasAccount ?? false
        
        DispatchQueue.main.async {
            self.PollTypeDelegate?.shouldReloadUIForPollId(pollId: (polld?.id)!,updatedPoll: polld)
        }
    }
    
}
