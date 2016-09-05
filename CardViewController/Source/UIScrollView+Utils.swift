//
//  UIScrollView+Utils.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 02/09/16.
//  Copyright © 2016 Magnus Eriksson. All rights reserved.
//

import Foundation

import UIKit

extension UIScrollView {
    
    func scrollToPageAtIndex(_ index: Int, animated: Bool = false) {
        let newX = CGFloat(index) * pageSize()
        setHorizontalContentOffset(newX, animated: animated)
    }
    
    /**
     "Safely" updates the scroll view's horizontal content offset within its bounds.
     Minimum value is 0 (i.e. left of first page).
     Maximum value is 'contentSize.width - pageSize' (i.e. left of last page)
     */
    func setHorizontalContentOffset(_ x: CGFloat, animated: Bool = false) {
        let newX = max(minimumHorizontalOffset(), min(maximumHorizontalOffset(), x))
        setContentOffset(CGPoint(x: newX, y: 0), animated: animated)
    }
    
    /**
     Calculates the current X-scroll percentage within the current page.
     Starts at index 0. E.g. if the scroll view is 50% between page 5 and 6, this function will return 4.5
     */
    func horizontalPercentScrolledInCurrentPage() -> CGFloat {
        let maxHorizontalOffset = pageSize()
        if maxHorizontalOffset > 0 {
            return (contentOffset.x / maxHorizontalOffset)
        }
        
        return 0
    }
    
    /**
     Minimum value is 0 (i.e. left of first page).
     */
    func minimumHorizontalOffset() -> CGFloat {
        return 0
    }
    
    /**
     Maximum value is 'contentSize.width - pageSize' (i.e. left of last page)
     */
    func maximumHorizontalOffset() -> CGFloat {
        return contentSize.width - pageSize()
    }
    
    /**
     Returns the current page number, or -1 if content offset is < 0
     */
    func currentPage() -> Int {
        guard contentOffset.x >= 0 else {
            return -1
        }
        
        let pageNumber = Int(contentOffset.x / pageSize())
        return pageNumber
    }
    
    func pageSize() -> CGFloat {
        //TODO: Configurable page size
        return bounds.size.width / 2
    }
}
