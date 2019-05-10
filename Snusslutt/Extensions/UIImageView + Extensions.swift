//
//  UIImageView + Extensions.swift
//  Snusslutt
//
//  Created by Knut Arild Slåtsve on 08/04/2019.
//  Copyright © 2019 Knut Arild Slåtsve. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class RoundedCornersUIImageView: UIImageView {
    
    @IBInspectable var borderColor: UIColor = UIColor.white {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 2.0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
}
