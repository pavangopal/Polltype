//
//  ViewController.swift
//  PollTest
//
//  Created by Pavan Gopal on 7/3/17.
//  Copyright © 2017 Pavan Gopal. All rights reserved.
//

import UIKit
import Polltype

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    
    var reuseId:[String] = []
    var models:[Int] = []
    var pollIdIndexPathMapping:[Int:IndexPath] = [:]
    var cachedHeight:[Int:CGSize] = [:] 
    
    var sizingCell :PolltypeCell?
    
    var updatedPolls:[IndexPath:Poll] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        Polltype.shared.configure(withHostUrl: "https://polltype-api.staging.quintype.io",imageCDN:"qt-staging-01.imgix.net")
        Polltype.shared.parentView = self.view
        Polltype.shared.PollTypeDelegate = self
        
        sizingCell = PolltypeCell(frame: CGRect(x: 0, y: 0, width: 375, height: 50))
        
        prepateModel()
    }
    
    func prepateModel(){
        let pollIDs:[Int] = [787, 890, 813,730]
        
        for i in 0..<pollIDs.count{
            models.append(pollIDs[i])
            
        }
        
    }
    
}

extension ViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,PolltypeDelegate,PolltypeCellDelegate{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell : UICollectionViewCell?
        let id = "PolltypeCell\(indexPath.row)"
        
        pollIdIndexPathMapping[models[indexPath.item]] = indexPath
        
        if reuseId.contains(id){
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
            
            let currentCell = cell as! PolltypeCell
            
            currentCell.delegate = self
            
            if let poll = updatedPolls[indexPath]{
                
                currentCell.configure(poll: poll)
                
            }
            
        }else{
            
            collectionView.register(PolltypeCell.self, forCellWithReuseIdentifier: id)
            
            reuseId.append(id)
            
            cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
            
            let currentCell = cell as! PolltypeCell
            
            currentCell.delegate = self
            
            currentCell.configure(id: models[indexPath.item])
            
        }
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let poll = updatedPolls[indexPath]{
            
            sizingCell?.configure(poll: poll)
            
            let size = sizingCell?.pollView.preferredLayoutSizeFittingSize(CGSize(width: UIScreen.main.bounds.width, height: CGFloat.greatestFiniteMagnitude))
            
            return size!
        }
        
        return CGSize(width: collectionView.frame.size.width, height: 50)
    }
    
    
    func shouldReloadUIForPollId(pollId:Int,updatedPoll:Poll?){
        
        let indexPath =  self.pollIdIndexPathMapping[pollId]
        
        updatedPolls[indexPath!] = updatedPoll
        
        self.collectionView.reloadData()
        
    }
    
    
    func pollData(poll:Poll){
        
        let indexPath =  self.pollIdIndexPathMapping[poll.id]
        
        updatedPolls[indexPath!] = poll
        
        self.collectionView.reloadData()
        
    }
    
}

