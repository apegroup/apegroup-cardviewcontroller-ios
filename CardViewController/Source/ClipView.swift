//
//  ClipView.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 04/09/16.
//  Copyright © 2016 Magnus Eriksson. All rights reserved.
//

import Foundation


class ClipView: UIView {
    
    var scrollView: UIScrollView!
    
    override func hitTest(_ cgPoint: CGPoint, with event: UIEvent?) -> UIView? {
        return point(inside: cgPoint, with: event) ? scrollView : nil
    }
}
