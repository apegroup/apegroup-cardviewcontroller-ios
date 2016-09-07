//
//  Interpolator.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 08/09/16.
//  Copyright © 2016 Magnus Eriksson. All rights reserved.
//

import Foundation

public struct Interpolator {
    
    //Formulas fetched from http://www.joshondesign.com/2013/03/01/improvedEasingEquations
    
    //MARK: Linear
    
    static func linear(_ input: CGFloat) -> CGFloat {
        return input
    }
    
    //MARK: Cubic
    
    static func easeInCubic(_ input: CGFloat) -> CGFloat {
        return pow(input, 3)
    }
    
    static func easeOutCubic(_ input: CGFloat) -> CGFloat {
        return 1 - easeInCubic(1 - input)
    }
    
    static func cubicOut(_ input: CGFloat) -> CGFloat {
        return 1 - pow(1 - input, 3)
    }
    
    static func cubicInOut(_ input: CGFloat) -> CGFloat {
        if input < 0.5 {
            return easeInCubic(input * 2) / 2
        }
        return 1 - easeInCubic((1 - input) * 2) / 2
    }

    
    //MARK: Quadratic
    
    static func easeOutQuad(_ input: CGFloat) -> CGFloat {
        return 1 - easeInQuad(1-input)
    }
    
    static func easeInQuad(_ input: CGFloat) -> CGFloat {
        return input*input
    }
    
    //MARK: Othher
    
    static func easeOut(_ input: CGFloat) -> CGFloat {
        return (cos((input + 1) * CGFloat(M_PI)) / 2.0) + 0.5
    }
}
