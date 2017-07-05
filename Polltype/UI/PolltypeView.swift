//
//  PolltypeView.swift
//  Polltype
//
//  Created by Pavan Gopal on 7/3/17.
//  Copyright © 2017 Pavan Gopal. All rights reserved.
//

import UIKit
import Ably


public class PolltypeView: UIView {
    
    enum Constants:Int {
        case container_TAG = 200
        case shareContainer_TAG = 300
        case poweredByText_TAG = 1000
        case activityIndicator_TAG = 2000
    }
    
    fileprivate let cardSectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    var pollChannel:ARTRealtimeChannel!
    var containerView:UIView!
    
    var poll:Poll!
    
    fileprivate var opinionButtons:[UIButton] = []
    
    public weak var pollDelegate:PolltypeCellDelegate?
    
    var questionLbl:UILabel = {
        let questionLbl = UILabel.init()
        questionLbl.translatesAutoresizingMaskIntoConstraints = false
        questionLbl.textColor = UIColor.black
        questionLbl.numberOfLines = 4
        return questionLbl
    }()
    
    var imageView:UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var pollDescription:UITextView = {
        let textView = UITextView.init()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = UIColor.lightGray
        return textView
    }()
    
    var voteButton:UIButton = {
        let voteButtond = UIButton.init(type: .custom)
        voteButtond.translatesAutoresizingMaskIntoConstraints = false
        voteButtond.backgroundColor = UIColor.init(hexColor: "#0165a7")
        //     voteButtond.setTitle("VOTE", forState: .Normal)
        voteButtond.titleEdgeInsets = UIEdgeInsets.init(top: 5, left: 12, bottom: 5, right: 12)
        voteButtond.setTitleColor(UIColor.white, for: .normal)
        return voteButtond
    }()
    
    var shareContainer:UIView = {
        
        let shareView = UIView.init()
        shareView.translatesAutoresizingMaskIntoConstraints = false
        shareView.tag = Constants.shareContainer_TAG.rawValue
        shareView.backgroundColor = UIColor.init(hexColor: "#f6f9fb")
        return shareView
        
    }()
    
    var shareButton:UIButton = {
        let shareBtn = UIButton.init(type: .custom)
        shareBtn.translatesAutoresizingMaskIntoConstraints = false
        shareBtn.setTitleColor(UIColor.init(hexColor: "#0165a7"), for: .normal)
        shareBtn.layer.borderColor = UIColor.init(hexColor: "#0165a7").cgColor
        shareBtn.layer.borderWidth = 3.0
        return shareBtn
    }()
    
    fileprivate var _pollTypeTapGesture:UITapGestureRecognizer?
    
    fileprivate var pollTypeTapGesture:UITapGestureRecognizer{
        
        if _pollTypeTapGesture != nil{
            _pollTypeTapGesture?.view?.removeGestureRecognizer(_pollTypeTapGesture!)
        }
        _pollTypeTapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.didTapOnPollType(_:)))
        return _pollTypeTapGesture!
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didTapOnPollType(_ sender:UITapGestureRecognizer){
        
        self.pollDelegate?.didTapOnPolltype(poll,view: self)
        
    }
    
    public func configure(storyElement:Poll?){
        self.pollDelegate = Polltype.shared
        
        if let existingActivityIndicator = self.viewWithTag(2000) as? UIActivityIndicatorView{
            
            existingActivityIndicator.removeFromSuperview()
        }
        
        if let polld = storyElement{
            self.pollDelegate?.didViewPoll(polld.id)
            self.configurePoll(polld)
        }
        else{
            //handle not loaded
            if let container = self.viewWithTag(Constants.container_TAG.rawValue){
                
                container.removeFromSuperview()
            }
            
            self.poll = nil
            let activityIndicatorView = UIActivityIndicatorView.init()
            activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            activityIndicatorView.tag = 2000
            activityIndicatorView.hidesWhenStopped = true
            activityIndicatorView.startAnimating()
            activityIndicatorView.activityIndicatorViewStyle = .gray
            self.addSubview(activityIndicatorView)
            
            let centerX = NSLayoutConstraint.init(item: activityIndicatorView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0)
            let centerY = NSLayoutConstraint.init(item: activityIndicatorView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
            
            self.addConstraint(centerX)
            self.addConstraint(centerY)
        }
    }
    
    func configurePoll(_ poll:Poll){
        self.poll = poll
        
        if self.poll.opinions.count == 0{
            return
        }
        
        self.createContainer()
        self.createOpinions()
    }
    
    func addImage(){
        
        self.containerView.addSubview(imageView)
        
        self.imageView.removeConstraints(self.imageView.constraints)
        
        let horizontalConstraints = NSLayoutConstraint.constraints( withVisualFormat: "H:|-(10)-[imageView]-(10)-|", options: [], metrics: nil, views: ["imageView":imageView])
        self.containerView.addConstraints(horizontalConstraints)
        let topConstraint = NSLayoutConstraint.init(item: imageView, attribute: .top, relatedBy: .equal, toItem: self.containerView, attribute: .top, multiplier: 1.0, constant: poll.shouldShowHeroImage() ? 8.0 : 0.0)
        self.containerView.addConstraint(topConstraint)
        
        
        var cgSize = UIScreen.main.bounds.size
        cgSize.width = cgSize.width - cardSectionInset.left - cardSectionInset.right - 20
        
        let imageSize = poll.shouldShowHeroImage() ? calculateImageSize(cgSize) : CGSize.init(width: calculateImageSize(cgSize).width, height: 0)
        
        let heightConstraint = NSLayoutConstraint.init(item: self.imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: imageSize.height)
        
        heightConstraint.priority = 750
        
        self.imageView.addConstraint(heightConstraint)
        
        imageView.setContentCompressionResistancePriority(999, for: .vertical)
        imageView.setContentHuggingPriority(750, for: .vertical)
        
        //        let imageBaseUrl = "http://" + (Quintype.publisherConfig?.cdn_image)! + "/"
        //        coverImageView.loadImage(url: imageBaseUrl + image + "?w=\(imageSize.width)", targetSize: CGSize(width: imageSize.width, height: imageSize.height),imageMetaData:(card?.hero_image_metadata))
        
        let image = UIImage(named: "polltypBG", in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        
        if self.poll.shouldShowHeroImage(){
            
            let imageURL = "http://" + Polltype.shared.imageCDN + "/" + self.poll.heroImageS3Key! + "?W=\(imageSize.width)"
            
            if imageView.image == nil{
                downloadImage(url: URL(string: imageURL)!)
            }
        }
        else{
            imageView.image = image
        }
        
        self.imageView.contentMode = .scaleToFill
        self.imageView.backgroundColor = UIColor.white
        self.imageView.clipsToBounds = true
        self.imageView.layoutIfNeeded()
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    
    func downloadImage(url: URL) {
        print("Download Started")
        getDataFromUrl(url: url) { (data, response, error)  in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                self.imageView.image = UIImage(data: data)
            }
        }
    }
    
    
    func addQuestion(){
        
        self.containerView.addSubview(questionLbl)
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(10)-[question]-(10)-|", options: [], metrics: nil, views: ["question":questionLbl])
        
        self.containerView.addConstraints(horizontalConstraints)
        let topConstraint = NSLayoutConstraint.init(item: self.questionLbl, attribute: .top, relatedBy: .equal, toItem: self.imageView, attribute: .bottom, multiplier: 1.0, constant: 12.0)
        self.containerView.addConstraint(topConstraint)
        questionLbl.font = UIFont.boldSystemFont(ofSize: 15)
        questionLbl.text = self.poll.question
        questionLbl.setContentCompressionResistancePriority(998, for: .vertical)
        
    }
    
    func calculateImageSize(_ targetSize:CGSize) -> CGSize{
        if self.poll.heroImageMetadata?.width == 0 ?? nil || self.poll.heroImageMetadata?.height == 0 ?? nil{
            self.poll.heroImageMetadata = nil
        }
        let widthDimension1 = CGFloat(self.poll.heroImageMetadata?.width ?? 4)
        let heightDimension1 = CGFloat(self.poll.heroImageMetadata?.height ?? 3)
        let newSize = CGSize(width:targetSize.width, height:(targetSize.width * heightDimension1) / widthDimension1)
        
        return newSize
        
    }
    
    func addDescription(){
        
        self.containerView.addSubview(pollDescription)
        let horizontalConstraints = NSLayoutConstraint.constraints( withVisualFormat: "H:|-(10)-[description]-(10)-|", options: [], metrics: nil, views: ["description":pollDescription])
        
        self.containerView.addConstraints(horizontalConstraints)
        
        let topConstraint = NSLayoutConstraint.init(item: self.pollDescription, attribute: .top, relatedBy: .equal, toItem: questionLbl, attribute: .bottom, multiplier: 1.0, constant: 12)
        
        self.pollDescription.setContentCompressionResistancePriority(1000, for: .vertical)
        self.pollDescription.setContentHuggingPriority(250, for: .vertical)
        
        if self.poll.pollDescription == nil || self.poll.pollDescription == ""{
            
            self.pollDescription.setContentCompressionResistancePriority(250, for: .vertical)
            self.pollDescription.setContentHuggingPriority(1000, for: .vertical)
        }
        
        self.containerView.addConstraint(topConstraint)
        self.pollDescription.text = self.poll.pollDescription?.html2String ?? ""
        
    }
    
    fileprivate func createOpinions(){
        
        opinionButtons.removeAll()
        addImage()
        addQuestion()
        addDescription()
        
        let opinions = self.poll.opinions
        
        for (index, value) in opinions.enumerated(){
            
            let opinionButton = ResizableButton.init(type: .custom)
            opinionButton.translatesAutoresizingMaskIntoConstraints = false
            
            
            opinionButton.tag = index
            opinionButton.titleLabel?.numberOfLines = 5
            opinionButton.titleLabel?.lineBreakMode = .byWordWrapping
            opinionButton.contentHorizontalAlignment = .left
            opinionButton.titleEdgeInsets = UIEdgeInsetsMake(10, 40, 10, 50)
            opinionButton.setTitleColor(UIColor.black, for: .normal)
            opinionButton.backgroundColor = UIColor.init(hexColor: "#f9f9f9")
            
            opinionButton.addTarget(self, action: #selector(self.didSelectOpinion(_:)), for: .touchUpInside)
            
            
            self.containerView.addSubview(opinionButton)
            self.containerView.setNeedsLayout()
            self.containerView.layoutIfNeeded()
            let horizontalConstraintsd = NSLayoutConstraint.constraints( withVisualFormat: "H:|-(12)-[opinion]-(12)-|", options: [], metrics: nil, views: ["opinion":opinionButton])
            
            let heightConstraint = NSLayoutConstraint.init(item: opinionButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
            heightConstraint.priority = 999
            
            opinionButton.addConstraint(heightConstraint)
            
            self.containerView.addConstraints(horizontalConstraintsd)
            
            if let votedOnn = self.poll.votedOn{
                if votedOnn == value.id{
                    opinionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
                    opinionButton.setTitle(value.title, for: UIControlState())
                    
                }
                else{
                    opinionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
                    opinionButton.setTitle(value.title, for: UIControlState())
                }
                
            }
            else{
                opinionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
                opinionButton.setTitle(value.title, for: UIControlState())
            }
            
            if let _ = self.poll.votedOn{
                if self.poll.isChangeVoteEnabled{
                    opinionButton.isUserInteractionEnabled = true
                }
                else{
                    opinionButton.isUserInteractionEnabled = false
                }
            }
            else{
                opinionButton.isUserInteractionEnabled = true
            }
            
            opinionButton.setTitle(value.title, for: UIControlState())
            // opinionButton.setNeedsLayout()
            opinionButton.layoutIfNeeded()
            let insets = opinionButton.titleEdgeInsets.top + opinionButton.titleEdgeInsets.bottom
            var constant = opinionButton.titleLabel?.frame.size.height ?? 0
            constant += insets
            heightConstraint.constant = constant
            opinionButton.setNeedsLayout()
            opinionButton.layoutIfNeeded()
            
            switch index {
            case 0:
                self.displayThankyouIfRequired(opinionButton, poll: self.poll, index: index)
                break
                
            case opinions.count - 1:
                
                voteButton.removeFromSuperview()
                self.containerView.addSubview(voteButton)
                
                
                let constraintBottom = NSLayoutConstraint.init(item: voteButton, attribute: .top, relatedBy: .equal, toItem: opinionButton, attribute: .bottom, multiplier: 1.0, constant: 12)
                self.containerView.addConstraint(constraintBottom)
                let prevButton = self.opinionButtons[index - 1]
                let constraintTop = NSLayoutConstraint.init(item: opinionButton, attribute: .top, relatedBy: .equal, toItem: prevButton, attribute: .bottom, multiplier: 1, constant: 8)
                self.containerView.addConstraint(constraintTop)
                
                break
                
            default:
                let prevButton = self.opinionButtons[index - 1]
                let constraint = NSLayoutConstraint.init(item: opinionButton, attribute: .top, relatedBy: .equal, toItem: prevButton, attribute: .bottom, multiplier: 1, constant: 8)
                self.containerView.addConstraint(constraint)
                break
            }
            
            if (poll.votedOn != nil || poll.showResult == Poll.ShowResults.always){
                
                self.addGradiant(opinionButton, percentage: value.percentVotes)
                
                if !shouldDisplayThankyou(){
                    self.addPercentage(opinionButton, percentage: value.percentVotes)
                }
                else{
                    if self.poll.votedOn! == value.id{
                        self.addPercentage(opinionButton, percentage: value.percentVotes)
                    }
                }
            }
            else{
                self.addGradiant(opinionButton, percentage: value.percentVotes)
                
            }
            
            self.addRadioButton(opinionButton)
            self.opinionButtons.append(opinionButton)
            opinionButton.radioButton.layoutIfNeeded()
            opinionButton.bringSubview(toFront: opinionButton.radioButton.superview!)
            opinionButton.setNeedsLayout()
            opinionButton.layoutIfNeeded()
            opinionButton.radioButton.layer.borderColor = UIColor.init(hexColor: "#59c2ef").cgColor
            opinionButton.radioButton.layer.borderWidth = 1.5
            opinionButton.bringSubview(toFront: opinionButton.titleLabel!)
            //        opinionButton.layoutSubviews()
            
            if let votedOnn = self.poll.votedOn{
                if votedOnn == value.id{
                    opinionButton.isVotedOn = true
                    opinionButton.makeSelected()
                    opinionButton.isUserInteractionEnabled = false
                    opinionButton.radioButton.isHidden = true
                }
                else{
                    opinionButton.radioButton.isHidden = false
                }
                
            }
            else{
                
                opinionButton.radioButton.isHidden = false
            }
            
            disableInteractionOnAnonVote(opinionButton)
        }
        
        let topperView = self.addVoteButton()
        self.addShareView(topperView)
        
        
    }
    
    func disableInteractionOnAnonVote(_ opButton:ResizableButton){
        if shouldDisplayThankyou(){
            
            opButton.isUserInteractionEnabled = false
        }
    }
    
    func displayThankyouIfRequired(_ opinionButton:ResizableButton, poll:Poll, index:Int){
        if shouldDisplayThankyou(){
            let thankyouView = PollTypeThankyou.instantiateFromNib()
            thankyouView.translatesAutoresizingMaskIntoConstraints = false
            self.containerView.addSubview(thankyouView)
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[thankyouView]-(0)-|", options: [], metrics: nil, views: ["thankyouView":thankyouView])
            self.containerView.addConstraints(horizontalConstraints)
            
            let topConstraint = NSLayoutConstraint.init(item: thankyouView, attribute: .top, relatedBy: .equal, toItem: self.pollDescription, attribute: .bottom, multiplier: 1.0, constant: 8)
            let bottomConstraint = NSLayoutConstraint.init(item: thankyouView, attribute: .bottom, relatedBy: .equal, toItem: opinionButton, attribute: .top, multiplier: 1.0, constant: -8)
            
            self.containerView.addConstraints([topConstraint, bottomConstraint])
            
            let widthConstraint = NSLayoutConstraint.init(item: thankyouView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 74)
            thankyouView.addConstraint(widthConstraint)
            
            thankyouView.displayVote(poll.votedOnModel?.percentVotes ?? 0)
        }
        else{
            let constraint = NSLayoutConstraint.init(item: opinionButton, attribute: .top, relatedBy: .equal, toItem: self.pollDescription, attribute: .bottom, multiplier: 1, constant: 12)
            self.containerView.addConstraint(constraint)
        }
    }
    
    func shouldDisplayThankyou() -> Bool{
        return (self.poll.isAnonymousVoteEnabled) && (!self.poll.hasAccount) && (self.poll.showResult == Poll.ShowResults.loggedInVoted) && self.poll.votedOn != nil
    }
    
    func addGradiant(_ button:UIButton, percentage:Int){
        if let gradientButton =  button as? ResizableButton{
            
            let viewd = UIView.init()
            viewd.tag = 69
            viewd.translatesAutoresizingMaskIntoConstraints = false
            viewd.isUserInteractionEnabled = false
            gradientButton.addSubview(viewd)
            let horizontalConstraints = NSLayoutConstraint.constraints( withVisualFormat: "H:|-(0)-[view]", options: [], metrics: nil, views: ["view":viewd])
            viewd.widthAnchor.constraint(equalToConstant: getWidthForProgress(gradientButton, percentage: percentage)).isActive = true
            let verticalConstraints = NSLayoutConstraint.constraints( withVisualFormat: "V:|-(0)-[view]-(0)-|", options: [], metrics: nil, views: ["view":viewd])
            gradientButton.addConstraints(horizontalConstraints)
            gradientButton.addConstraints(verticalConstraints)
            //  viewd.backgroundColor = UIColor.init(red: 234.0/255.0, green: 242.0/155.0, blue: 249/255.0, alpha: 1.0)
            viewd.backgroundColor = UIColor.init(hexColor: "#EAF2F9")
            
            gradientButton.percentageView = viewd
        }
        
    }
    
    func addShareView(_ topView:UIView){
        
        self.shareContainer.removeFromSuperview()
        
        self.containerView.addSubview(shareContainer)
        
        let horizontalConstraints = NSLayoutConstraint.constraints( withVisualFormat: "H:|-(0)-[shareContainer]-(0)-|", options: [], metrics: nil, views: ["shareContainer":shareContainer])
        self.containerView.addConstraints(horizontalConstraints)
        
        let bottomConstraint = NSLayoutConstraint.init(item: shareContainer, attribute: .bottom, relatedBy: .equal, toItem: self.containerView, attribute: .bottom, multiplier: 1.0, constant: 0)
        self.containerView.addConstraint(bottomConstraint)
        
        let topConstraint = NSLayoutConstraint.init(item: shareContainer, attribute: .top, relatedBy: .equal, toItem: topView, attribute: .bottom, multiplier: 1.0, constant: 12)
        topConstraint.priority = 999
        self.containerView.addConstraint(topConstraint)
        
        self.addShareSubviews()
    }
    
    func shareButtonClick(_ sender:UIButton){
        
        
        
        if self.poll != nil{
            self.pollDelegate?.didClickOnShare(self.poll,view: sender)
        }
    }
    
    func addShareSubviews(){
        
        shareButton.removeFromSuperview()
        self.shareContainer.addSubview(shareButton)
        
        self.shareButton.removeConstraints(self.shareButton.constraints)
        
        shareButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13.0)
        
        shareButton.titleEdgeInsets = UIEdgeInsetsMake(0, -5.0, 0, 0)
        shareButton.imageView?.contentMode = .scaleAspectFit
        shareButton.imageEdgeInsets = UIEdgeInsetsMake(10.0, -5.0, 10.0, 5.0)
        
        let image = UIImage(named: "share", in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        
        shareButton.setImage(image, for: UIControlState())
        shareButton.setTitle("SHARE", for: UIControlState())
        
        shareButton.addTarget(self, action: #selector(self.shareButtonClick(_:)), for: .touchUpInside)
        
        let verticalConstraints = NSLayoutConstraint.constraints( withVisualFormat: "V:|-(20)-[shareButton]-(20)-|", options: [], metrics: nil, views: ["shareButton":shareButton])
        
        self.shareContainer.addConstraints(verticalConstraints)
        
        let heightConstraint = NSLayoutConstraint.init(item: shareButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 35)
        heightConstraint.priority = 999
        shareButton.addConstraint(heightConstraint)
        
        let horizontalConstraint = NSLayoutConstraint.init(item: shareButton, attribute: .leading, relatedBy: .equal, toItem: shareContainer, attribute: .leading, multiplier: 1.0, constant: 10)
        horizontalConstraint.priority = 990
        shareContainer.addConstraint(horizontalConstraint)
        
        let widthConstraint = NSLayoutConstraint.init(item: shareButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 105)
        widthConstraint.priority = 900
        shareButton.addConstraint(widthConstraint)
        
        let centerYConstraint = NSLayoutConstraint.init(item: shareButton, attribute: .centerY, relatedBy: .equal, toItem: shareContainer, attribute: .centerY, multiplier: 1, constant: 0)
        self.shareContainer.addConstraint(centerYConstraint)
        
        self.shareContainer.layoutIfNeeded()
        let poweredByText = PoweredByPollTypeView.instantiateFromNib()
        
        if let logoImageView = poweredByText.viewWithTag(200){
            logoImageView.isUserInteractionEnabled = true
            logoImageView.addGestureRecognizer(self.pollTypeTapGesture)
        }
        
        poweredByText.translatesAutoresizingMaskIntoConstraints = false
        poweredByText.tag = Constants.poweredByText_TAG.rawValue
        if let olderView = shareContainer.viewWithTag(Constants.poweredByText_TAG.rawValue){
            olderView.removeFromSuperview()
        }
        
        poweredByText.backgroundColor = UIColor.clear
        
        self.shareContainer.addSubview(poweredByText)
        
        let poweredCenterY = NSLayoutConstraint.init(item: poweredByText, attribute: .centerY, relatedBy: .equal, toItem: shareContainer, attribute: .centerY, multiplier: 1.0, constant: 0)
        
        self.shareContainer.addConstraint(poweredCenterY)
        
        let poweredTrailingConstraint = NSLayoutConstraint.init(item: poweredByText, attribute: .trailing, relatedBy: .equal, toItem: shareContainer, attribute: .trailing, multiplier: 1.0, constant: -3)
        self.shareContainer.addConstraint(poweredTrailingConstraint)
        
        let horizontalSpacingConstraint = NSLayoutConstraint.init(item: shareButton, attribute: .right, relatedBy: .greaterThanOrEqual, toItem: poweredByText, attribute: .left, multiplier: 1.0, constant: -5)
        horizontalSpacingConstraint.priority = 900
        // self.shareContainer.addConstraint(horizontalSpacingConstraint)
        
        let powredByHeightConstraint = NSLayoutConstraint.init(item: poweredByText, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30)
        poweredByText.addConstraint(powredByHeightConstraint)
        
    }
    
    func getWidthForProgress(_ button:ResizableButton,percentage:Int) -> CGFloat{
        if percentage == 0{
            return 0
        }
        
        // return button.frame.width
        
        let widthForOneVote = CGFloat(button.frame.width/100.0)
        return widthForOneVote * CGFloat(percentage)
        
    }
    
    func didSelectOpinion(_ sender:ResizableButton){
        
        self.opinionButtons = opinionButtons.map({ (button) -> UIButton in
            
            if let resizableButton = button as? ResizableButton{
                resizableButton.makeUnselected()
                return resizableButton
            }
            return button
        })
        
        sender.makeSelected()
        
        
    }
    
    func didClickOnLogin(){
        
        self.pollDelegate?.didClickOnLogin(self.poll, view: self)
    }
    
    func didClickOnVote(){
        
        let filteredButtons = self.opinionButtons.filter { (selectedButton) -> Bool in
            if let resizableButton = selectedButton as? ResizableButton{
                
                return resizableButton.isSelectedOpinion && !resizableButton.isVotedOn
            }
            return false
        }
        
        if let selectedOpinionButton = filteredButtons.first{
            self.pollDelegate?.didClickOnVote(self.poll, opinionIndex: selectedOpinionButton.tag, view: self)
        }
    }
    
    
    
    fileprivate func addRadioButton(_ opinionButton:ResizableButton){
        let radioContainerView = UIView.init()
        radioContainerView.translatesAutoresizingMaskIntoConstraints = false
        radioContainerView.backgroundColor = UIColor.clear
        radioContainerView.isUserInteractionEnabled = false
        opinionButton.addSubview(radioContainerView)
        
        let verticalConstraints = NSLayoutConstraint.constraints( withVisualFormat: "V:|-(0)-[radioContainerView]-(0)-|", options: [], metrics: nil, views: ["radioContainerView":radioContainerView])
        opinionButton.addConstraints(verticalConstraints)
        
        let leadingConstraint = NSLayoutConstraint.init(item: radioContainerView, attribute: .leading, relatedBy: .equal, toItem: opinionButton, attribute: .leading, multiplier: 1.0, constant: 0)
        opinionButton.addConstraint(leadingConstraint)
        
        let widthConstraint = NSLayoutConstraint.init(item: radioContainerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: opinionButton.titleEdgeInsets.left)
        radioContainerView.addConstraint(widthConstraint)
        
        let radioButton = UIButton.init()
        radioButton.translatesAutoresizingMaskIntoConstraints = false
        radioContainerView.addSubview(radioButton)
        let centerXConstraint = NSLayoutConstraint.init(item: radioButton, attribute: .centerX, relatedBy: .equal, toItem: radioContainerView, attribute: .centerX, multiplier: 1.0, constant: 0)
        let centerYConstraint = NSLayoutConstraint.init(item: radioButton, attribute: .centerY, relatedBy: .equal, toItem: radioContainerView, attribute: .centerY, multiplier: 1.0, constant: 0)
        let widthConstraintRadio = NSLayoutConstraint.init(item: radioButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 10)
        let heightCOnstraintRadio = NSLayoutConstraint.init(item: radioButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 10)
        radioContainerView.addConstraint(centerXConstraint)
        radioContainerView.addConstraint(centerYConstraint)
        radioButton.addConstraint(widthConstraintRadio)
        radioButton.addConstraint(heightCOnstraintRadio)
        opinionButton.radioButton = radioButton
        
        
    }
    
    
    func addVoteButton() -> UIView{
        
        
        if self.voteButton.superview == nil{
            self.containerView.addSubview(voteButton)
        }
        
        self.voteButton.removeConstraints(self.voteButton.constraints)
        
        let widthConstraint = NSLayoutConstraint.init(item: voteButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        widthConstraint.priority = 1000
        self.voteButton.addConstraint(widthConstraint)
        
        let heightConstraint = NSLayoutConstraint.init(item: voteButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 28)
        heightConstraint.priority = 999
        self.voteButton.addConstraint(heightConstraint)
        
        voteButton.titleLabel?.numberOfLines = 1
        voteButton.titleLabel?.lineBreakMode = .byWordWrapping
        
        self.voteButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        
        let returnView:UIView?
        switch shouldDisplayThankyou() {
        case true:
            let centerXConstraint = NSLayoutConstraint.init(item: self.voteButton, attribute: .centerX, relatedBy: .equal, toItem: self.containerView, attribute: .centerX, multiplier: 1.0, constant: 0)
            self.containerView.addConstraint(centerXConstraint)
            self.voteButton.setTitle("LOGIN", for: UIControlState())
            voteButton.backgroundColor = UIColor.init(hexColor: "#0165a7")
            self.voteButton.removeTarget(self, action: #selector(self.didClickOnVote), for: .touchUpInside)
            self.voteButton.addTarget(self, action: #selector(self.didClickOnLogin), for: .touchUpInside)
            returnView = self.addLoginString(self.voteButton)
            break
        case false:
            let leadingConstraint = NSLayoutConstraint.init(item: voteButton, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: self.containerView, attribute: .leading, multiplier: 1.0, constant: 5.0)
            leadingConstraint.priority = 1000
            self.containerView.addConstraint(leadingConstraint)
            self.voteButton.removeTarget(self, action: #selector(self.didClickOnLogin), for: .touchUpInside)
            self.voteButton.addTarget(self, action: #selector(self.didClickOnVote), for: .touchUpInside)
            
            let trailingConstraint = NSLayoutConstraint.init(item: voteButton, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1.0, constant: -16.0)
            self.containerView.addConstraint(trailingConstraint)
            
            if let _ = self.poll.votedOn{
                
                if !self.poll.isChangeVoteEnabled{
                    voteButton.backgroundColor = UIColor.lightGray
                    
                }
                else{
                    voteButton.backgroundColor = UIColor.init(hexColor: "#0165a7")
                }
                
                self.voteButton.setTitle("CHANGE VOTE", for: UIControlState())
            }
            else{
                self.voteButton.setTitle("VOTE", for: UIControlState())
                voteButton.backgroundColor = UIColor.init(hexColor: "#0165a7")
            }
            returnView = voteButton
            break
        }
        
        
        voteButton.layoutIfNeeded()
        var width = voteButton.titleLabel?.frame.size.width ?? 104
        width = width + voteButton.titleEdgeInsets.left + voteButton.titleEdgeInsets.right
        var height = voteButton.titleLabel?.frame.size.height ?? 28
        height = height + voteButton.titleEdgeInsets.top + voteButton.titleEdgeInsets.bottom
        
        let fittedSize = voteButton.titleLabel?.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)) ?? CGSize(width: width,height: height)
        widthConstraint.constant = fittedSize.width + voteButton.titleEdgeInsets.left + voteButton.titleEdgeInsets.right
        
        //        let bottomConstraint = NSLayoutConstraint.init(item: self.voteButton, attribute: .Bottom, relatedBy: .Equal, toItem: self.containerView, attribute: .Bottom, multiplier: 1.0, constant: -12)
        //        self.containerView.addConstraint(bottomConstraint)
        //
        return returnView!
        
    }
    
    func addLoginString(_ topView:UIView)-> UIView{
        
        let loginLabel = UILabel.init()
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        loginLabel.textColor = UIColor.lightGray
        loginLabel.font = UIFont.systemFont(ofSize: 12.0)
        loginLabel.text = "to view complete results"
        self.containerView.addSubview(loginLabel)
        
        let topConstraint = NSLayoutConstraint.init(item: loginLabel, attribute: .top, relatedBy: .equal, toItem: topView, attribute: .bottom, multiplier: 1.0, constant: 8)
        self.containerView.addConstraint(topConstraint)
        
        let centerXConstraint = NSLayoutConstraint.init(item: loginLabel, attribute: .centerX, relatedBy: .equal, toItem: self.containerView, attribute: .centerX, multiplier: 1.0, constant: 0)
        self.containerView.addConstraint(centerXConstraint)
        return loginLabel
    }
    
    
    
    fileprivate func addPercentage(_ opinionButton:ResizableButton, percentage:Int){
        
        let percentageView = UIView.init()
        percentageView.backgroundColor = UIColor.clear
        percentageView.translatesAutoresizingMaskIntoConstraints = false
        opinionButton.addSubview(percentageView)
        let verticialConstraints = NSLayoutConstraint.constraints( withVisualFormat: "V:|-(0)-[percentageView]-(0)-|", options: [], metrics: nil, views: ["percentageView":percentageView])
        opinionButton.addConstraints(verticialConstraints)
        
        let trailingConstraint = NSLayoutConstraint.init(item: percentageView, attribute: .trailing, relatedBy: .equal, toItem: opinionButton, attribute: .trailing, multiplier: 1.0, constant: 0)
        opinionButton.addConstraint(trailingConstraint)
        let widthConstraint = NSLayoutConstraint.init(item: percentageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: opinionButton.titleEdgeInsets.right)
        percentageView.addConstraint(widthConstraint)
        
        let percentageLabel = UILabel.init()
        
        percentageLabel.textColor = UIColor.black
        
        percentageLabel.font = UIFont.boldSystemFont(ofSize: 12.0)
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        percentageView.addSubview(percentageLabel)
        
        
        let centerXConstraint = NSLayoutConstraint.init(item: percentageLabel, attribute: .centerX, relatedBy: .equal, toItem: percentageView, attribute: .centerX, multiplier: 1.0, constant: 0)
        percentageView.addConstraint(centerXConstraint)
        
        let centerYConstraint = NSLayoutConstraint.init(item: percentageLabel, attribute: .centerY, relatedBy: .equal, toItem: percentageView, attribute: .centerY, multiplier: 1.0, constant: 0)
        percentageView.addConstraint(centerYConstraint)
        
        percentageLabel.text = "\(percentage)%"
        opinionButton.percentageLabel = percentageLabel
    }
    
    
    
    
    
    fileprivate func createContainer(){
        
        if let container = self.viewWithTag(Constants.container_TAG.rawValue){
            
            container.removeFromSuperview()
        }
        
        containerView = UIView.init()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.tag = Constants.container_TAG.rawValue
        self.containerView.backgroundColor = UIColor.white
        self.addSubview(containerView)
        
        let horizontalConstraints = NSLayoutConstraint.constraints( withVisualFormat: "H:|-(0)-[containerView]-(0)-|", options: [], metrics: nil, views: ["containerView":containerView])
        
        let verticalConstraints = NSLayoutConstraint.constraints( withVisualFormat: "V:|-(0)-[containerView]-(0)-|", options: [], metrics: nil, views: ["containerView":containerView])
        
        self.addConstraints(verticalConstraints)
        self.addConstraints(horizontalConstraints)
        
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        if voteButton.superview != nil{
            voteButton.layer.cornerRadius = voteButton.frame.size.height/2
        }
        
        if shareButton.superview != nil{
            shareButton.layer.borderWidth = 1.5
            shareButton.layer.cornerRadius = shareButton.frame.size.height/2
        }
        
        if self.containerView != nil{
            self.containerView.layoutIfNeeded()
        }
        self.layoutIfNeeded()
    }
    
    
    open  func preferredLayoutSizeFittingSize(_ targetSized:CGSize) -> CGSize{
        
        let targetSize = targetSized
        
        let widthConstraint = NSLayoutConstraint.init(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: targetSize.width)
        
        widthConstraint.priority = 999
        
        self.addConstraint(widthConstraint)
        self.setNeedsUpdateConstraints()
        self.updateConstraintsIfNeeded()
        self.setNeedsLayout()
        self.layoutIfNeeded()
        var changeSize = UILayoutFittingCompressedSize
        changeSize.width = targetSize.width
        let size = self.systemLayoutSizeFitting(changeSize, withHorizontalFittingPriority: 1000, verticalFittingPriority: 250)
        
        self.removeConstraint(widthConstraint)
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        return CGSize.init(width: targetSize.width, height: size.height)
    }
}

extension String {
    
    var html2AttributedString: NSAttributedString? {
        guard
            let data = data(using: String.Encoding.utf8)
            else { return nil }
        do {
            return try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:NSNumber(value: String.Encoding.utf8.rawValue)], documentAttributes: nil)
            
        } catch let error as NSError {
            print(error.localizedDescription)
            return  nil
        }
    }
    
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}
