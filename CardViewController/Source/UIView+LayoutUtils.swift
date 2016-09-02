//
//  UIView+LayoutUtils.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 03/09/16.
//  Copyright © 2016 Magnus Eriksson. All rights reserved.
//

import UIKit

extension UIView {
    
    func addViewsHorizontally(_ views: [UIView]) {
        //TODO: Configurable margin
        let margin = UIScreen.main.bounds.width / 4
        
        var prevView: UIView?
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            
            if prevView == nil {
                //First view - Pin to view's leading anchor
                addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(margin)-[view]",
                                                              options: [.alignAllCenterY],
                                                              metrics: ["margin":margin],
                                                              views: ["view":view]))
            } else {
                //All other views - to to previous view's trailing anchor
                view.leadingAnchor.constraint(equalTo: prevView!.trailingAnchor).isActive = true
            }
            
            prevView = view;
        }
        
        //Last view - pin to container view's trailing anchor
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[view]-(margin)-|",
                                                      options: [.alignAllCenterY],
                                                      metrics: ["margin":margin],
                                                      views: ["view":prevView!]))
    }
}
