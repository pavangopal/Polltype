////
////  ViewController.swift
////  PollSample
////
////  Created by Arjun P A on 24/12/16.
////  Copyright © 2016 Arjun P A. All rights reserved.
////
//
//import UIKit
//import Ably
//
//class ViewController: UIViewController {
//    
//    var models:[Int] = []
//    
//    var polls:[Int:Poll] = [:]
//    
//    var sizingCell:Dictionary<String,UIView> = [:]
//    
//    var pollIndexPathMapping:[Int:IndexPath] = [:]
//    typealias LOGIN_COMPLETION = () -> ()
//    var loginCompletion:LOGIN_COMPLETION?
//    
//    var reuseId:[String] = []
//    var loadedPolls:[IndexPath] = []
//    
//    fileprivate var _api:APIManager?
//    
//    var isConnected = true
//    
//    var api:APIManager{
//        get{
//            if _api == nil{
//                _api = APIManager.init()
//            }
//            return _api!
//        }
//        set{
//            _api = newValue
//        }
//    }
//    
//    //ably
//    
//    var ablyToken:String?
//    
//    var pollChannel: ARTRealtimeChannel!
//    var ablyManager:AblyManager!
//    
//    let defaults = UserDefaults.standard
//    
//    
//    private var _ablyParseManager:AblyParseManager?
//    var ablyParseManager:AblyParseManager{
//        get{
//            if _ablyParseManager == nil{
//                _ablyParseManager = AblyParseManager.init()
//            }
//            return _ablyParseManager!
//        }
//        set{
//            _ablyParseManager = newValue
//        }
//    }
//    
//    var _loginWebView:UIWebView?
//    
//    var loginWebView:UIWebView?{
//        get{
//            if _loginWebView == nil{
//                _loginWebView = UIWebView.init()
//                _loginWebView?.translatesAutoresizingMaskIntoConstraints = false
//            }
//            return _loginWebView!
//        }
//        set{
//            _loginWebView = nil
//        }
//    }
//    
//    @IBOutlet weak var collection_view:UICollectionView!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.collection_view.delegate = self
//        self.collection_view.dataSource = self
//        self.doRegistrations()
//        
//        self.prepateModel()
//        self.fetchAblyToken()
//        
//    }
//    
//    func prepateModel(){
//        let pollIDs:[Int] = [787, 890, 813,730]
//        
//        for i in 0..<pollIDs.count{
//            models[i] = pollIDs[i]
//            
//        }
//        
//    }
//    
//    func getPoll(_ pollID:Int){
//        
//        api.fetchPoll(pollID) {[weak self] (poll, error) in
//            
//            if let _ = error{
//                
//            }
//            else{
//                guard let weakSelf = self else {return}
//                
//                self?.polls[(poll?.id)!] = poll
//                
//                DispatchQueue.main.async {
//                    if let indexPath = weakSelf.pollIndexPathMapping[poll!.id]{
//                        
//                        self?.collection_view.reloadItems(at: [indexPath])
//                    }
//                }
//                
//            }
//        }
//    }
//    
//    func doRegistrations(){
//        let nib1 = UINib.init(nibName: "PolltypeCell", bundle: Bundle(identifier: "com.quintype.Polltype"))
//        self.sizingCell["PolltypeCell"] = nib1.instantiate(withOwner: self, options: nil)[0] as! PolltypeView
//        
//    }
//    
//}
//
//extension ViewController:UICollectionViewDataSource{
//    
//    internal func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 1
//    }
//    
//    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        
//        return models.count
//    }
//    
//    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        
//        var cell : UICollectionViewCell?
//        let id = "PolltypeCell\(indexPath.row)"
//        
//        if reuseId.contains(id){
//            cell = self.collection_view.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
//            
//            let currentCell = cell as! PolltypeView
//            currentCell.pollDelegate = self
//            
//            let poll = polls[models[indexPath.item]]
//            
//            currentCell.configure(poll)
//            
//            if self.isConnected{
//                
//                if self.ablyToken != nil{
//                    
//                    if let pollUnwrapped = poll{
//                        
//                        if pollChannel == nil{
//                            
//                            self.pollChannel = ablyManager.client.channels.get("polltype-clients:results-\(pollUnwrapped.id)")
//                            
//                            self.watchPollChange(channel: self.pollChannel)
//                        }
//                    }
//                }
//            }
//            
//        }else{
//            let nib1 = UINib.init(nibName: "PolltypeCell", bundle: Bundle(identifier: "com.quintype.Polltype"))
//            self.collection_view.register(nib1, forCellWithReuseIdentifier: id)
//            
//            reuseId.append(id)
//            
//            cell = self.collection_view.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
//            
//            let currentCell = cell as! PolltypeView
//            currentCell.pollDelegate = self
//            
//            currentCell.configure(nil)
//            
//            pollIndexPathMapping[models[indexPath.item]] = indexPath
//            
//            self.getPoll(models[indexPath.item])
//        }
//        
//
//        
//        return cell!
//    }
//}
//
//extension ViewController:UICollectionViewDelegateFlowLayout{
//    
//    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        
//        if let poll = polls[models[indexPath.item]]{
//            
//            let sizingCell = self.sizingCell["PolltypeCell"] as! PolltypeView
//            sizingCell.configure(poll)
//            
//            let targetSize = CGSize.init(width: UIScreen.main.bounds.size.width, height: 0.5 * UIScreen.main.bounds.size.width)
//            let size =  sizingCell.preferredLayoutSizeFittingSize(targetSize)
//            return size
//            
//        }else{
//            
//            return  CGSize.init(width: UIScreen.main.bounds.size.width, height: 50)
//        }
//        
//    }
//}
//
//
//extension ViewController:PolltypeCellDelegate{
//    
//    
//    func shouldPerformReloadForPendingPoll(_ poll: Poll) -> Bool {
//        return false
//    }
//    
//    func didViewPoll(_ pollID: Int) {
//        
//    }
//    
//    func didClickOnLogin(_ poll: Poll, view cell: PolltypeView) {
//        
//    }
//    
//    func didTapOnPolltype(_ poll:Poll){
//        
//    }
//    
//    func didClickOnShare(_ poll: Poll) {
//        
//    }
//    
//    func didClickOnVote(_ poll: Poll, opinionIndex: Int, view cell: PolltypeView) {
//        print("did enter here")
//        
//        api.voteIntend(poll.id, opinionID: poll.opinions[opinionIndex].id)
//        
//        if poll.hasAccount{
//            
//            self.vote(poll, opinionIndex: opinionIndex, cell: cell)
//        }
//        else{
//            DispatchQueue.main.async(execute: {
//                self.showWebView(cell)
//            })
//            
//            self.loginCompletion = {
//                self.closeWebview(self.loginWebView!)
//                self.vote(poll, opinionIndex: opinionIndex, cell: cell)
//            }
//        }
//    }
//    
//    func vote(_ poll:Poll, opinionIndex:Int, cell: PolltypeView){
//        
//        api.vote(poll,storyURL: nil,opinionIndex: opinionIndex) { (polld, error) in
//            
//            
//            if let _ = error{
//                return
//            }
//            
//            let someIndex = self.models.index(where: { (storyElement) -> Bool in
//                return storyElement == polld?.id ?? 0
//            })
//            
//            if let index = someIndex{
//                
//                
//                self.polls[self.models[index]] = polld
//                
//                self.models = self.models.map({ (storyELement) -> Int in
//                    
//                    self.polls[self.models[index]]?.hasAccount = polld?.hasAccount ?? false
//                    return storyELement
//                })
//                
//                for value in Array(self.pollIndexPathMapping.values){
//                    
//                        if let cell = self.collection_view.cellForItem(at: value) as? PolltypeView{
//                            cell.poll.hasAccount = polld?.hasAccount ?? false
//                        }
//                    
//                }
//                
//                if let indexpath = self.pollIndexPathMapping[poll.id]{
//                    DispatchQueue.main.async {
//                        
//                        self.collection_view.reloadItems(at: [indexpath])
//                        
//                    }
//                }
//            }
//        }
//    }
//    
//    
//}
//
//extension ViewController:UIWebViewDelegate{
//    
//    public func showWebView(_ cell: PolltypeView?){
//        loginWebView!.removeFromSuperview()
//        self.view.addSubview(self.loginWebView!)
//        self.view.bringSubview(toFront: self.loginWebView!)
//        self.loginWebView?.delegate = self
//        
//        
//        loginWebView?.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
//        loginWebView?.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
//        loginWebView?.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
//        loginWebView?.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true
//        
//        let closeButton = UIButton.init(type: .custom)
//        closeButton.tag = 20
//        closeButton.backgroundColor = UIColor.darkGray
//        closeButton.setTitle("X", for: UIControlState())
//        closeButton.setTitleColor(UIColor.lightText, for: .normal)
//        closeButton.translatesAutoresizingMaskIntoConstraints = false
//        closeButton.addTarget(self, action: #selector(ViewController.closeWebview(_:)), for: .touchUpInside)
//        self.loginWebView?.addSubview(closeButton)
//        self.loginWebView?.bringSubview(toFront: closeButton)
//        closeButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
//        closeButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
//        
//        closeButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20).isActive = true
//        closeButton.topAnchor.constraint(equalTo: (self.loginWebView?.topAnchor)!, constant: 20).isActive = true
//        
//        self.loginWebView?.loadRequest(URLRequest.init(url: URL.init(string: APIManager.BASEURL + "login")!))
//    }
//    
//    func closeWebview(_ sender:UIWebView){
//        
//        self.loginWebView?.removeFromSuperview()
//        self.loginWebView?.delegate = nil
//        self.loginWebView = nil
//    }
//    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
//        
//        
//        return true
//    }
//    
//    public func webViewDidFinishLoad(_ webView: UIWebView) {
//        
//        guard let url = webView.request?.url?.absoluteString.components(separatedBy: "/")else {return}
//        
//        url.forEach({ (data) in
//            print(data)
//            if (data == "me#_=_") || (data ==  "me"){
//                
//                print("LoggedIn")
//                
//                if let someCompletion = loginCompletion{
//                    someCompletion()
//                }
//            }
//            
//        })
//    }
//    
//}
//
//extension ViewController{
//    
//    func watchPollChange(channel:ARTRealtimeChannel){
//        
//        if self.isConnected{
//            
//            channel.attach()
//            
//            channel.subscribe({ (message) in
//                
//                print(message)
//                
//                guard let messageData = message.data else {return}
//                do{
//                    let data = try JSONSerialization.data(withJSONObject: messageData as! NSDictionary, options: .prettyPrinted)
//                    print("ABLY JSON: \(String.init(data: data, encoding: String.Encoding.utf8))")
//                    
//                    self.ablyParseManager.startParse(message.data as? [String:AnyObject], completion: {[weak self] (poll) in
//                        
//                        guard let weakSelf = self else{ return }
//                        
//                        if let somePoll = poll{
//                            
//                            var shouldReload = false
//                            
//                            for (_,poll) in weakSelf.polls{
//                                
//                                shouldReload =  poll.isPollDataStale(newPoll: somePoll)
//                                
//                                if !shouldReload{
//                                    return
//                                }else{
//                                    self?.polls[somePoll.id]?.opinions = somePoll.opinions
//                                    break
//                                }
//                            }
//                            
//                            DispatchQueue.main.async {
//                                if let indexPath = weakSelf.pollIndexPathMapping[somePoll.id]{
//                                    print("POLL ID:\(somePoll.id)")
//                                    print("INDEXPATH:\(indexPath)")
//                                    weakSelf.collection_view.reloadItems(at: [indexPath])
//                                }
//                            }
//                        }
//                    })
//                }catch{
//                    
//                    print("Error caught")
//                    
//                }
//                
//            })
//        }
//        
//    }
//    
//    func fetchAblyToken(){
//        
//        self.api.fetchAblyToken({[weak self] (token, error) in
//            
//            guard let weakSelf = self else {return}
//            
//            if let someError = error{
//                
//                print(someError.localizedDescription)
//            }
//            else{
//                
//                print("TOKEN: \(token)")
//                if let someTOken = token{
//                    
//                    weakSelf.ablyToken = someTOken
//                    
//                    weakSelf.ablyManager = AblyManager.init(key: someTOken)
//                    self?.ablyManager = AblyManager.init(key: someTOken)
//                }
//            }
//        })
//    }
//}
//
//
