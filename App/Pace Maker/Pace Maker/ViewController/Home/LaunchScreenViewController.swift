//
//  LaunchScreenViewController.swift
//  Pace Maker
//
//  Created by Kyungho on 2021/07/09.
//

import UIKit

class LaunchScreenViewController: UIViewController {
    
    @IBOutlet weak var launchLables: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.launchLables.shake()
            self.performSegue(withIdentifier: "Home", sender: nil)
        }
        
    }

}
