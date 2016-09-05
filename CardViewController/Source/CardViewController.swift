//
//  CardViewController.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 02/09/16.
//  Copyright © 2016 Magnus Eriksson. All rights reserved.
//

import UIKit
import GLKit

public struct CardViewControllerFactory {
    
    static public func make(cards: [UIViewController]) -> CardViewController {
        
        let nib = UINib(nibName: String(describing: CardViewController.self),
                        bundle: Bundle(for: CardViewController.self))
            .instantiate(withOwner: nil, options: nil)
        
        let vc = nib.first as! CardViewController
        vc.cardViewControllers = cards
        return vc
    }
}

public class CardViewController: UIViewController {
    
    //MARK: Configurable
    
    public var degreesToRotate: CGFloat = 45
    public var isPagingEnabled = true
    
    //MARK: Properties
    
    fileprivate var currentCardIndex: Int = 0
    fileprivate var cardViewControllers: [UIViewController] = []
    
    private var hasLaidOutSubviews = false
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    
    //MARK: IBOutlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    //MARK: Rotation related events
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateOrientationRelatedConstraints()
    }
    
    /// Activates/deactivates the appropriate leading and trailing constraints, depending on the current device orientation
    private func updateOrientationRelatedConstraints() {
        guard let firstCard = cardViewControllers.first?.view,
            let lastCard = cardViewControllers.last?.view,
            let contentView = firstCard.superview else {
                return
        }
        
        //Deactivate old constraints
        //TODO: Remove idle constraints (instead of deactivating)
        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false
        
        //Create new constraints with the updated border margin
        let borderMargin = self.view.bounds.width/4
        leadingConstraint = firstCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: borderMargin)
        trailingConstraint = contentView.trailingAnchor.constraint(equalTo: lastCard.trailingAnchor, constant: borderMargin)
        
        //Activate new constraints
        leadingConstraint?.isActive = true
        trailingConstraint?.isActive = true
        
        //TODO: Re-apply rotation
    }
    
    //MARK: Life cycle
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Wait until 'viewDidAppear' to layout the 'card-views' since 'self.view'
        // has not been laid out prior to that (and therefore we don't have a reliable 'self.view.frame')
        if !hasLaidOutSubviews {
            hasLaidOutSubviews = true
            add(childControllers: cardViewControllers)
        }
    }

    //MARK: Private
    
    private func add(childControllers: [UIViewController]) {
        let borderMargin = self.view.bounds.width/4
        var prevView: UIView?
        for (index, cardViewController) in cardViewControllers.enumerated() {

            //Add each view controller as a child
            addChildViewController(cardViewController)
            
            //Add view as subview
            let cardView = cardViewController.view!
            contentView.addSubview(cardView)
            cardView.translatesAutoresizingMaskIntoConstraints = false
            cardView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
            cardView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5).isActive = true
            cardView.heightAnchor.constraint(equalTo: cardView.widthAnchor).isActive = true
            
            //Set up horizontal constraints
            if prevView == nil {
                //First view - Pin card to superview's leading anchor
                leadingConstraint = cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: borderMargin)
                leadingConstraint?.isActive = true
                
            } else {
                //All other views - to to previous view's trailing anchor
                cardView.leadingAnchor.constraint(equalTo: prevView!.trailingAnchor).isActive = true
            }
            
            //Apply initial rotation for all views except the first
            if index > 0 {
                rotate(cardView.layer, degrees: -degreesToRotate)
            }
            
            cardViewController.didMove(toParentViewController: self)
            prevView = cardView;
        }
        
        //Last view - pin to container view's trailing anchor
        trailingConstraint = contentView.trailingAnchor.constraint(equalTo: prevView!.trailingAnchor, constant: borderMargin)
        trailingConstraint?.isActive = true
    }
    
    /// Applies a 3D rotation to the received layer
    fileprivate func rotate(_ layer: CALayer, degrees: CGFloat) {
        var perspective = CATransform3DIdentity
        perspective.m34 = -1/500 //500 seems to be a good value
        layer.transform = CATransform3DRotate(perspective, CGFloat(GLKMathDegreesToRadians(Float(degrees))), 0, 1, 0)
    }
}

extension CardViewController: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let isGoingBackwards = scrollView.currentPage() < currentCardIndex
        
        //"percentScrolledInPage" represents the X-scroll percentage within the current page, starting at index 0.
        //E.g. if the scroll view is 50% between page 5 and 6, the  will be 4.5
        let percentScrolledInPage = scrollView.horizontalPercentScrolledInCurrentPage()
        
        //The transition progress of the leftmost page involved in the transition
        let leftTransitionProgress = percentScrolledInPage - CGFloat(scrollView.currentPage())
        
        //The transition progress of the rightmost page involved in the transition (the opposite of the leftTransitionProgress)
        let rightTransitionProgress = (1 - leftTransitionProgress)
        
        //The transition progress of the current/source page
        let sourceTransitionProgress = isGoingBackwards ? -rightTransitionProgress : leftTransitionProgress
        
        //The transition progress of the destination page
        let destTransitionProgress = isGoingBackwards ? leftTransitionProgress : -rightTransitionProgress
        
        //The index of the leftmost element involved in the transition
        let transitionLeftElementIndex = scrollView.currentPage()
        
        //The index of the rightmost element involved in the transition
        let transitionRightElementIndex = transitionLeftElementIndex + 1
        
        //The index of the transition source element
        let transitionSourceElementIndex = isGoingBackwards ? transitionRightElementIndex : transitionLeftElementIndex
        
        //The index of the transition destination element
        let transitionDestinationElementIndex = isGoingBackwards ? transitionLeftElementIndex : transitionRightElementIndex
        
        //Fetch cards involved in the transition
        guard let sourceCard = card(at: transitionSourceElementIndex),
            let destinationCard = card(at: transitionDestinationElementIndex) else {
                return
        }
        
        //Calculate degrees to rotate
        let sourceDegrees = sourceTransitionProgress * degreesToRotate
        let destDegrees = destTransitionProgress * degreesToRotate
        
        //Update rotation transform accordingly
        rotate(sourceCard.layer, degrees: sourceDegrees)
        rotate(destinationCard.layer, degrees: destDegrees)
    }
    
    /// Returns the card at the received index, or nil if the index is out of bounds
    private func card(at index: Int) -> UIView? {
        guard index >= 0 && index < cardViewControllers.count else {
            return nil
        }
        
        return cardViewControllers[index].view
    }
    
    //Update the target content offset to the nearest card
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard isPagingEnabled else {
            return
        }
        guard let cardSize = card(at: 0)?.bounds.width else {
            return
        }
        
        let cardSpacing: CGFloat = 0
        let minIndex: CGFloat = 0
        let maxIndex = CGFloat(cardViewControllers.count)
        
        //Calculate x coordinate of destination, including velocity
        let destX = scrollView.contentOffset.x + velocity.x
        
        //Calculate index of destination card
        var destCardIndex = round(destX / (cardSize + cardSpacing))
        
        //Avoid "jumping" to initial position when making very small swipes
        if velocity.x > 0 {
            destCardIndex = ceil(destX / (cardSize + cardSpacing))
        } else {
            destCardIndex = floor(destX / (cardSize + cardSpacing))
        }
        
        //Ensure index is within bounds
        destCardIndex = max(minIndex, min(maxIndex, destCardIndex))
        
        //Update target content offset
        targetContentOffset.pointee.x = destCardIndex * (cardSize + cardSpacing)
    }
    
    ///Save the index of the current card when the scroll view has stopped scrolling
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            currentCardIndex = scrollView.currentPage()
        }
    }
    
    ///Save the index of the current card when the scroll view has stopped scrolling
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentCardIndex = scrollView.currentPage()
    }
}
