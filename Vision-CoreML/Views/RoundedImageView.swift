//
//  RoundedImageView.swift
//  Vision-CoreML
//
//  Created by akshay Grover on 2017-08-05.
//  Copyright © 2017 akshay Grover. All rights reserved.
//

import UIKit

class RoundedImageView: UIImageView {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = self.frame.height / 2
        
    }

}
