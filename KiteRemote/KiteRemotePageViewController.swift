//
//  KiteRemotePageViewController.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 21/07/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import UIKit

class KiteRemotePageViewController: UIPageViewController {
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("autopilot"),
                UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("manual")]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //dataSource = self
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .Forward,
                               animated: true,
                               completion: nil)
        }
    }
}

// MARK: UIPageViewControllerDataSource

extension KiteRemotePageViewController {
    
    func setViewController(index: Int) {
        setViewControllers([orderedViewControllers[index]],
                           direction: .Forward,
                           animated: true,
                           completion: nil)
    }
    
    
    func next(viewController: UIViewController) {
        
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
            return
        }
        
        let nextIndex = viewControllerIndex + 1
        
        // User is on the last view controller and swiped right to loop to
        // the first view controller.
        guard orderedViewControllers.count != nextIndex else {
            setViewController(0) // select the first one
            return
        }
        
        setViewController(nextIndex)
    }
    
    
//    func pageViewController(pageViewController: UIPageViewController,
//                            viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
//        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
//            return nil
//        }
//        
//        let previousIndex = viewControllerIndex - 1
//        
//        // User is on the first view controller and swiped left to loop to
//        // the last view controller.
//        guard previousIndex >= 0 else {
//            return orderedViewControllers.last
//        }
//        
//        guard orderedViewControllers.count > previousIndex else {
//            return nil
//        }
//        
//        return orderedViewControllers[previousIndex]
//    }
//    
//    func pageViewController(pageViewController: UIPageViewController,
//                            viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
//        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
//            return nil
//        }
//        
//        let nextIndex = viewControllerIndex + 1
//        let orderedViewControllersCount = orderedViewControllers.count
//        
//        // User is on the last view controller and swiped right to loop to
//        // the first view controller.
//        guard orderedViewControllersCount != nextIndex else {
//            return orderedViewControllers.first
//        }
//        
//        guard orderedViewControllersCount > nextIndex else {
//            return nil
//        }
//        
//        return orderedViewControllers[nextIndex]
//    }
    
}