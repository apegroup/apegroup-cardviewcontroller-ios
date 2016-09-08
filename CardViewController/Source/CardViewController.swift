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

public protocol CardViewControllerDelegate {
    
    func cardViewController(_ cardViewController: CardViewController,
                            didSelect viewController: UIViewController,
                            at index: Int)
}

public typealias TransitionInterpolator = (_ transitionProgress: CGFloat) -> (CGFloat)

public class CardViewController: UIViewController {
    
    //MARK: Configurable
    
    public var delegate: CardViewControllerDelegate? = nil
    
    ///The number of degrees to rotate the background cards
    public var degreesToRotateCard: CGFloat = 45
    
    ///The z translation factor applied to the cards during transition. The formula is (cardWidth * factor)
    public var cardZTranslationFactor: CGFloat = 1/3
    
    ///The alpha of the background cards
    public var backgroundCardAlpha: CGFloat = 0.65
    
    ///If paging between the cards should be enabled
    public var isPagingEnabled = true
    
    ///The transition interpolation applied to the source card during transition
    public var sourceTransitionInterpolator: TransitionInterpolator = CardInterpolator.cubicOut
    
    ///The transition interpolation applied to the destination card during transition
    public var destinationTransitionInterpolator: TransitionInterpolator = CardInterpolator.cubicOut
    
    //MARK: Properties
    
    private var hasLaidOutSubviews = false
    fileprivate var currentCardIndex: Int = 0
    fileprivate var cardViewControllers: [UIViewController] = []
    
    //Spacing between cards
    fileprivate let cardSpacing: CGFloat = 0
    
    //The current page before the trait collection changes, e.g. prior to rotation occurrs
    private var pageIndexBeforeTraitCollectionChange: Int = 0
    
    //MARK: IBOutlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIStackView!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewTapGestureRecognizer: UITapGestureRecognizer!
    
    //MARK: Life cycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        contentView.spacing = cardSpacing
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Wait until 'viewDidAppear' to layout the 'card-views' since 'self.view'
        // has not been laid out prior to that (and therefore we don't have a reliable 'self.view.frame')
        if !hasLaidOutSubviews {
            hasLaidOutSubviews = true
            add(childControllers: cardViewControllers)
        }
    }
    
    private func add(childControllers: [UIViewController]) {
        for cardViewController in cardViewControllers {
            //Add each view controller as a child
            addChildViewController(cardViewController)
            
            //Insert view in the horizontal stack view
            let cardView = cardViewController.view!
            contentView.addArrangedSubview(cardView)
            
            //Set up width and height constraints
            cardView.translatesAutoresizingMaskIntoConstraints = false
            cardView.heightAnchor.constraint(equalTo: cardView.widthAnchor).isActive = true
            
            //A card is half the size of the view
            //FIXME: Ugly: If we change this value we must also change the 'pageSize()' method is 'UIScrollView+Utils' (together with any eventual card spacing)
            cardView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5).isActive = true
            
            cardViewController.didMove(toParentViewController: self)
        }
    }
    
    //MARK: Rotation related events
    
    override public func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        pageIndexBeforeTraitCollectionChange = scrollView.currentPage()
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        //Restore previous page.
        //A slight delay is required since the scroll view's frame size has not yet been updated to reflect the new trait collection.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CATransaction.begin()
            self.updateOrientationRelatedConstraints()
            self.applyInitialCardTransform()
            self.scrollView.scrollToPageAtIndex(self.pageIndexBeforeTraitCollectionChange, animated: false)
            CATransaction.commit()
        }
    }
    
    /// Updates the leading and trailing constraints to be 1/4 of the device width
    private func updateOrientationRelatedConstraints() {
        let borderMargin = self.view.bounds.width/4
        leadingConstraint.constant = borderMargin
        trailingConstraint.constant = borderMargin
    }
    
    
    //MARK: Helper
    
    /// Returns the card at the received index, or nil if the index is out of bounds
    fileprivate func card(at index: Int) -> UIView? {
        guard index >= 0 && index < cardViewControllers.count else {
            return nil
        }
        
        return cardViewControllers[index].view
    }
    
    //MARK: Card navigation
    
    @IBAction func onScrollViewTapped(_ sender: UITapGestureRecognizer) {
        guard let currentCard = card(at: currentCardIndex) else {
            return
        }
        
        var selectedCardIndex = -1
        let touchPoint = sender.location(in: contentView)
        if touchPoint.x > currentCard.frame.maxX {
            selectedCardIndex = currentCardIndex + 1
        } else if touchPoint.x < currentCard.frame.minX {
            selectedCardIndex = currentCardIndex - 1
        } else {
            let currentCardViewController = cardViewControllers[currentCardIndex]
            delegate?.cardViewController(self, didSelect: currentCardViewController, at: currentCardIndex)
            return
        }
        
        guard card(at: selectedCardIndex) != nil else {
            return
        }
        
        scrollViewWillScrollToCard()
        scrollView.scrollToPageAtIndex(selectedCardIndex, animated: true)
    }
    
    ///Prepares the scroll view prior to programatically scrolling to a card
    private func scrollViewWillScrollToCard() {
        scrollView.isScrollEnabled = false
        contentViewTapGestureRecognizer.isEnabled = false
    }
    
    ///Restores the scroll view after programatically scrolling to a card
    fileprivate func scrollViewDidScrollToCard() {
        scrollView.isScrollEnabled = true
        contentViewTapGestureRecognizer.isEnabled = true
    }
    
    
    //MARK: Card transform
    
    private func applyInitialCardTransform() {
        for (index, cardViewController) in cardViewControllers.enumerated() {
            let cardView = cardViewController.view!
            
            if index == currentCardIndex {
                let zTranslation = (cardView.bounds.width * cardZTranslationFactor)
                applyViewTransformation(to: cardView,
                                        degrees: 0,
                                        alpha: 1,
                                        zTranslation: zTranslation,
                                        rotateBeforeTranslate: true)
            } else {
                let direction: CGFloat = index < currentCardIndex ? 1 : -1
                applyViewTransformation(to: cardView,
                                        degrees: (direction * degreesToRotateCard),
                                        alpha: backgroundCardAlpha,
                                        zTranslation: 0,
                                        rotateBeforeTranslate: true)
            }
        }
    }
    
    fileprivate func applyViewTransformation(to view: UIView,
                                             degrees: CGFloat,
                                             alpha: CGFloat,
                                             zTranslation: CGFloat,
                                             rotateBeforeTranslate: Bool) {
        view.alpha = alpha
        
        if rotateBeforeTranslate {
            CATransform3DMakeYRotationAndZTranslation(view.layer, degrees: degrees, zTranslation: zTranslation)
        } else {
            CATransform3DMakeZTranslationAndYRotation(view.layer, zTranslation: zTranslation, degrees: degrees)
        }
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
        var sourceTransitionProgress = isGoingBackwards ? rightTransitionProgress : leftTransitionProgress
        sourceTransitionProgress = sourceTransitionInterpolator(sourceTransitionProgress)
        sourceTransitionProgress *= isGoingBackwards ? -1 : 1
        
        //The transition progress of the destination page
        var destTransitionProgress = isGoingBackwards ? leftTransitionProgress : rightTransitionProgress
        destTransitionProgress = destinationTransitionInterpolator(destTransitionProgress)
        destTransitionProgress *= isGoingBackwards ? 1 : -1
        
        //The index of the leftmost element involved in the transition
        let transitionLeftElementIndex = scrollView.currentPage()
        
        //The index of the rightmost element involved in the transition
        let transitionRightElementIndex = transitionLeftElementIndex + 1
        
        //The index of the transition source element
        let transitionSourceElementIndex = isGoingBackwards ? transitionRightElementIndex : transitionLeftElementIndex
        
        //The index of the transition destination element
        let transitionDestinationElementIndex = isGoingBackwards ? transitionLeftElementIndex : transitionRightElementIndex
        

        if let sourceCard = card(at: transitionSourceElementIndex) {
            //Gradually remove y rotation (i.e. move towards an y rotation of zero)
            let sourceDegrees = sourceTransitionProgress * degreesToRotateCard
            
            //Gradually move towards a normal alpha (i.e. move towards an alpha value of one)
            let sourceAlpha = max(backgroundCardAlpha, abs(destTransitionProgress))
            
            //Gradually move closer to the camera (i.e. move towards a positive Z translation)
            let maxZTranslation = (sourceCard.bounds.width * cardZTranslationFactor)
            let sourceZTranslation = abs(destTransitionProgress * maxZTranslation)
            
            applyViewTransformation(to: sourceCard, degrees: sourceDegrees, alpha: sourceAlpha, zTranslation: sourceZTranslation, rotateBeforeTranslate: true)
        }
        
        if let destCard = card(at: transitionDestinationElementIndex) {
            //Gradually add y rotation (i.e. move towards an y rotation of 'self.degreesToRotate')
            let destDegrees = destTransitionProgress * degreesToRotateCard
            
            //Gradually move towards a faded alpha (i.e. move towards an alpha value of 0..1)
            let destAlpha = max(backgroundCardAlpha, abs(sourceTransitionProgress))
            let maxZTranslation = (destCard.bounds.width * cardZTranslationFactor)
            
            //Gradually move away to the camera (i.e. move back towards the normal z translation of zero)
            let destZTranslation = abs(sourceTransitionProgress * maxZTranslation)
            applyViewTransformation(to: destCard, degrees: destDegrees, alpha: destAlpha, zTranslation: destZTranslation, rotateBeforeTranslate: false)
        }
    }
        
    
    ///Apply paging by updating the target content offset to the nearest card
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard isPagingEnabled else {
            return
        }
        guard let cardSize = card(at: 0)?.bounds.width else {
            return
        }
        
        let minIndex: CGFloat = 0
        let maxIndex = CGFloat(cardViewControllers.count)
        
        //Calculate x coordinate of destination, including velocity
        let velocityBoostFactor: CGFloat = 10
        let destX = scrollView.contentOffset.x + (velocity.x * velocityBoostFactor)
        
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
    
    ///Called when the scroll view ends scrolling programatically (e.g. when a user taps on a card)
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        currentCardIndex = scrollView.currentPage()
        
        //Restore the settings
        scrollViewDidScrollToCard()
    }
}
