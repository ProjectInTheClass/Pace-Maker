//
//  NavigationController.swift
//  Pace Maker
//
//  Created by Kyungho on 2021/07/07.
//

import UIKit

class NavigationController: UINavigationController {

    // MARK: Navigation Controller Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        setFont()
    }
    
    // MARK: Methods
    
    func setFont()
    {
        // set font for title
        self.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "NotoSansKR-Light", size: 20)!]
        
        // set font for Largetitle
        self.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "NotoSansKR-Light", size: 30)!]
        
        // set font for navigation bar buttons
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "NotoSansKR-Light", size: 15)!], for: UIControl.State.normal)
    }
}
