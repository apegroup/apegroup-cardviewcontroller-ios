//
//  CardViewController.swift
//  CardViewController
//
//  Created by Magnus Eriksson on 02/09/16.
//  Copyright © 2016 Magnus Eriksson. All rights reserved.
//

import UIKit


public struct CardViewControllerFactory {
    
    static public func make(cards: [UIViewController]) -> CardViewController {
        
        let nib = UINib(nibName: String(describing: CardViewController.self),
                        bundle: Bundle(for: CardViewController.self))
            .instantiate(withOwner: nil, options: nil)
        
        let vc = nib.first as! CardViewController
        vc.cards = cards
        return vc
    }
}

public class CardViewController: UIViewController {
    
    //MARK: Configurable
    
    let degreesToRotate: CGFloat = 45
    
    //MARK: Properties
    
    fileprivate var currentPageIndex: Int = 0
    
    fileprivate var cards: [UIViewController] = [] {
        
        willSet {
            //TODO: Remove previous cards
        }
        
        didSet {
            add(controllers: cards)
        }
    }
    
    //MARK: IBOutlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    //MARK: Life cycle

    
    //MARK: Private
    
    private func add(controllers: [UIViewController]) {
        cards.forEach { addChildViewController($0) }
        contentView.addViewsHorizontally(cards.flatMap { $0.view })
        
        cards.forEach { controller in
            let controllerView = controller.view!
            NSLayoutConstraint.activate([
                controllerView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5),
                controllerView.heightAnchor.constraint(equalTo: controllerView.widthAnchor),
                controllerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
                ])
        }

        var perspective = CATransform3DIdentity
        perspective.m34 = -1/500
        
        cards.flatMap{$0.view}.dropFirst().forEach {
            $0.layer.transform = CATransform3DRotate(perspective, -degreesToRadians(degreesToRotate), 0, 1, 0)
        }
        
        cards.forEach { $0.didMove(toParentViewController: self) }
    }
}

extension CardViewController: UIScrollViewDelegate {
    
    
    //Scroll view with paging
    //Each page is a child view controller's view
    //
    /*
     When scrolling view:
     - if dest view:
     - rotate the source and dest views interactively
     - set alpha
     */
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let isGoingBackwards = scrollView.currentPage() < currentPageIndex
        
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

        //Calculate radians from transition progress
        let sourceRads = degreesToRadians(sourceTransitionProgress * degreesToRotate)
        let destRads = degreesToRadians(destTransitionProgress * degreesToRotate)
        
        //Update rotation transform accordingly
        var perspective = CATransform3DIdentity
        perspective.m34 = -1/500
        sourceCard.layer.transform = CATransform3DRotate(perspective, sourceRads, 0, 1, 0)
        destinationCard.layer.transform = CATransform3DRotate(perspective, destRads, 0, 1, 0)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        //Meta data
        let minIndex: CGFloat = 0
        let maxIndex = CGFloat(cards.count)
        let cardWidth: CGFloat = UIScreen.main.bounds.width / 2
        let cardSpacing: CGFloat = 0
        
        //Calculate x coordinate of destination, including velocity
        let destX = scrollView.contentOffset.x + velocity.x             //TODO: * 60.0 What is this "* 60" ?
        
        //Calculate index of destination
        var destCardIndex = round(destX / (cardWidth + cardSpacing))
        
        //Avoid "jumping" to initial position when making very small swipes
        if velocity.x > 0 {
            destCardIndex = ceil(destX / (cardWidth + cardSpacing))
        } else {
            destCardIndex = floor(destX / (cardWidth + cardSpacing))
        }
        
        //Ensure index is within bounds
        if destCardIndex < minIndex {
            destCardIndex = minIndex
        } else if destCardIndex > maxIndex {
            destCardIndex = maxIndex
        }
        
        //Update target content offset
        targetContentOffset.pointee.x = destCardIndex * (cardWidth + cardSpacing)
    }
    
    fileprivate func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return degrees * 3.1459 / 180
    }
    
    private func card(at index: Int) -> UIView? {
        guard index >= 0 && index < cards.count else {
            return nil
        }
        
        return cards[index].view
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            //Save the current page index
            currentPageIndex = scrollView.currentPage()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //Save the current page index
        currentPageIndex = scrollView.currentPage()
    }
}


