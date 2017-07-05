//
//  ResizableExtension.swift
//  PollSample
//
//  Created by Arjun P A on 24/12/16.
//  Copyright © 2016 Arjun P A. All rights reserved.
//

import Foundation
import UIKit

class ResizableButton: UIButton {
    
    
    struct ColorConstants {
        
        static let selectionColor = UIColor.init(hexColor: "#59c2ee")
        static let UnSelectionColor = UIColor.black
        static let radioButtonColor = UIColor.init(hexColor: "#59c2ef")
        static let votedColor = UIColor.init(hexColor: "#59c2ee")
    }
    
    var percentageLabel:UILabel?
    var radioButton:UIButton!
    var isSelectedOpinion:Bool = false
    var isVotedOn:Bool = false
    var percentageView:UIView?
    
    internal override class var layerClass : AnyClass{
        return CAGradientLayer.self
    }
    
    var colors:Array<UIColor>?{
        get{
            if let cgColors = (self.layer as! CAGradientLayer).colors{
                
                var uiColors:Array<UIColor> = []
                for color in cgColors{
                    uiColors.append(UIColor.init(cgColor: color as! CGColor))
                }
                return uiColors
            }
            return nil
        }
        
        set{
            var cgColors:[CGColor] = []
            
            if let colorsd = newValue{
                
                for uiColor in colorsd{
                    
                    cgColors.append(uiColor.cgColor)
                }
                (self.layer as! CAGradientLayer).colors = cgColors
            }
            
        }
    }
    
    var locations:Array<NSNumber>?{
        
        get{
            return (self.layer as! CAGradientLayer).locations
        }
        
        set{
            if let someValue = newValue{
                (self.layer as! CAGradientLayer).locations = someValue
            }
        }
    }
    
    var startPoint:CGPoint{
        get{
            return (self.layer as! CAGradientLayer).startPoint
        }
        
        set{
            (self.layer as! CAGradientLayer).startPoint = newValue
        }
    }
    
    var endPoint:CGPoint{
        
        get{
            return (self.layer as! CAGradientLayer).endPoint
        }
        
        set{
            (self.layer as! CAGradientLayer).endPoint = newValue
        }
    }
    
    var type:String{
        get{
            return (self.layer as! CAGradientLayer).type
        }
        
        set{
            (self.layer as! CAGradientLayer).type = newValue
        }
    }
    
    func makeSelected(){
        self.isSelectedOpinion = true
        self.radioButton.backgroundColor = ColorConstants.radioButtonColor
        
        if self.isVotedOn{
            //do additional things
            
            self.percentageLabel?.textColor = ColorConstants.selectionColor
            self.setTitleColor(ColorConstants.votedColor, for: .normal)
        }
        else{
            self.percentageLabel?.textColor = ColorConstants.UnSelectionColor
            self.setTitleColor(ColorConstants.selectionColor, for: .normal)
        }
    }
    
    func makeUnselected(){
        if self.isVotedOn{
            self.radioButton.backgroundColor = ColorConstants.radioButtonColor
            self.percentageLabel?.textColor = ColorConstants.selectionColor
            self.setTitleColor(ColorConstants.votedColor, for: .normal)
            self.isSelectedOpinion = true
            return
        }
        
        self.percentageLabel?.textColor = ColorConstants.UnSelectionColor
        
        self.setTitleColor(ColorConstants.UnSelectionColor, for: .normal)
        self.isSelectedOpinion = false
        self.radioButton.backgroundColor = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.radioButton != nil{
            radioButton.layer.cornerRadius = radioButton.bounds.size.width/2
            
            radioButton.setImage(UIImage.image(ColorConstants.radioButtonColor), for: .selected)
            
        }
        
        self.layer.cornerRadius = 10.0
        
        let mask = CAShapeLayer.init()
        mask.frame = self.bounds
        mask.path = UIBezierPath.init(roundedRect: mask.bounds, byRoundingCorners: [.bottomLeft,.topLeft], cornerRadii: CGSize.init(width: 10, height: 10)).cgPath
        self.percentageView?.layer.mask = mask
        
        self.clipsToBounds = true
        
        
        
    }
    
}

extension UIImage{
    
    class func image(_ with:UIColor) -> UIImage{
        let rect = CGRect.init(x: 0, y: 0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

