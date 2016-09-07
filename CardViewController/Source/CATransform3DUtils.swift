//
//  CATransform3DUtils.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 08/09/16.
//  Copyright © 2016 Magnus Eriksson. All rights reserved.
//

import GLKit

let cameraPerspective: CGFloat = -1/500 //500 seems to be a good value

func CATransform3DMakeYRotationAndZTranslation(_ layer: CALayer, degrees: CGFloat, zTranslation: CGFloat) {
    var perspective = CATransform3DIdentity
    perspective.m34 = cameraPerspective
    layer.transform = perspective
    layer.transform = CATransform3DRotate(layer.transform, CGFloat(GLKMathDegreesToRadians(Float(degrees))), 0, 1, 0)
    layer.transform = CATransform3DTranslate(layer.transform, 0, 0, zTranslation)
}

func CATransform3DMakeZTranslationAndYRotation(_ layer: CALayer, zTranslation: CGFloat, degrees: CGFloat) {
    var perspective = CATransform3DIdentity
    perspective.m34 = cameraPerspective
    layer.transform = perspective
    layer.transform = CATransform3DTranslate(layer.transform, 0, 0, zTranslation)
    layer.transform = CATransform3DRotate(layer.transform, CGFloat(GLKMathDegreesToRadians(Float(degrees))), 0, 1, 0)
}
