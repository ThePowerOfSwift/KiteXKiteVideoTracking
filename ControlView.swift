//
//  Control.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 02/08/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import UIKit

class ControlView: UIView {
    
    var baseLink: BaseLink? {
        didSet {
            if let baseLink = baseLink {
                baseLink.stateChangeIsConnected = {
                    state in
                    
                    if state {
                        self.segmentState.selectedSegmentIndex = 0
                    } else {
                        self.segmentState.selectedSegmentIndex = 1
                    }
                    
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    var next: (Void -> Void)?

    @IBOutlet weak var contentView: UIView?
    @IBOutlet weak var segmentState: UISegmentedControl!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func connect(sender: UIButton) {
        baseLink?.socket.connect()
        activityIndicator.startAnimating()
        
    }

    @IBAction func disconnect(sender: UIButton) {
        baseLink?.socket.disconnect()
        activityIndicator.startAnimating()
    }
    
    
    @IBAction func nextView(sender: UIButton) {
        next?()
    }
    
    override init(frame: CGRect) { // for using CustomView in code
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) { // for using CustomView in IB
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        NSBundle.mainBundle().loadNibNamed("ControlView", owner: self, options: nil)
        guard let content = contentView else { return }
        content.frame = self.bounds
        content.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        self.addSubview(content)
    }
    
    override func awakeFromNib() {
        segmentState.selectedSegmentIndex = 1
    }

    
}