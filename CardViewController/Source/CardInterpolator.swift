//
//  CardInterpolator.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 08/09/16.
//  Copyright © 2016 Magnus Eriksson. All rights reserved.
//

import Foundation

public struct CardInterpolator {
    
    //Formulas fetched from http://www.joshondesign.com/2013/03/01/improvedEasingEquations
    
    //MARK: Linear
    
    public static func linear(_ input: CGFloat) -> CGFloat {
        return input
    }
    
    //MARK: Cubic
    
    public static func easeInCubic(_ input: CGFloat) -> CGFloat {
        return pow(input, 3)
    }
    
    public static func easeOutCubic(_ input: CGFloat) -> CGFloat {
        return 1 - easeInCubic(1 - input)
    }
    
    public static func cubicOut(_ input: CGFloat) -> CGFloat {
        return 1 - pow(1 - input, 3)
    }
    
    public static func cubicInOut(_ input: CGFloat) -> CGFloat {
        if input < 0.5 {
            return easeInCubic(input * 2) / 2
        }
        return 1 - easeInCubic((1 - input) * 2) / 2
    }

    
    //MARK: Quadratic
    
    public static func easeOutQuad(_ input: CGFloat) -> CGFloat {
        return 1 - easeInQuad(1-input)
    }
    
    public static func easeInQuad(_ input: CGFloat) -> CGFloat {
        return input*input
    }
    
    //MARK: Othher
    
    public static func easeOut(_ input: CGFloat) -> CGFloat {
        return (cos((input + 1) * CGFloat(M_PI)) / 2.0) + 0.5
    }
}
