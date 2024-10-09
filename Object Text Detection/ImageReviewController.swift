//
//  ImageReviewController.swift
//  EnhancedCamera
//
//  Created by Raja on 09/10/24.
//

import UIKit

class ImageReviewController: UIViewController {

    @IBOutlet weak var reviewImgView: UIImageView!
    
    var capturedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reviewImgView.image = capturedImage
    }

}
