# CardViewController 

## Description:
- A "card-like" scroll view with a configurable transition effect.
- Supports both Portrait and Landscape

- Configurable:
  - degrees to rotate cards
  - distance to move cards back/forth from/to camera (z translation)
  - source and destination card interpolation (a set of predefined functions available or provide your own function)
  - alpha values of cards
  - enable/disable card paging

### Transition interpolation examples

#### Source ease out cubic, Destination ease out cubic
![easeoutcubic](https://cloud.githubusercontent.com/assets/653946/18344270/df51bbae-75b6-11e6-88e6-58030ca75a10.gif)

#### Source linear, Destination linear
![linear](https://cloud.githubusercontent.com/assets/653946/18344271/df615064-75b6-11e6-8164-131a210a38fa.gif)

#### Source ease in cubic, Destination ease out cubic
![easeincubic_easeoutcubic](https://cloud.githubusercontent.com/assets/653946/18349478/efee004c-75d1-11e6-9d05-2ce2c70b2fc9.gif)

## Installation:
  - Fetch with Carthage, e.g:
  - 'github "apegroup/aepegroup-cardviewcontroller-ios"'

## Usage example:
Get started with 3 easy steps:
  1. Set up cards (i.e. UIViewControllers) to be presented in the CardViewController 
 
  2. Create the CardViewController

  3. *Optional* Configure the CardViewController

```swift
import CardViewController

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
  //1. Create view controllers to be presented in the CardViewController:
  let cardViewControllers: [UIViewController] = createViewControllers(count: 4)

  //2. Create the cardViewController:
  let cardVc = CardViewControllerFactory.make(cards: cardViewControllers)

  //3. *Optional* Configure the card view controller:

  cardVc.delegate = self

  //The number of degrees to rotate the background cards
  cardVc.degreesToRotateCard = 45

  //The alpha of the background cards
  cardVc.backgroundCardAlpha = 0.65

  //The z translation factor applied to the cards during transition
  cardVc.cardZTranslationFactor = 1/3

  //If paging between the cards should be enabled
  cardVc.isPagingEnabled = true

  //The transition interpolation applied to the source and destination card during transition
  //The CardInterpolator contains some predefined functions, but feel free to provide your own.
  cardVc.sourceTransitionInterpolator = CardInterpolator.cubicOut
  cardVc.destinationTransitionInterpolator = CardInterpolator.cubicOut


  self.window = UIWindow()
  window?.rootViewController = cardVc
  window?.makeKeyAndVisible()
  return true
}

extension AppDelegate: CardViewControllerDelegate {
  func cardViewController(_ cardViewController: CardViewController, didSelect viewController: UIViewController, at index: Int) {
    print("did select card at index: \(index)")
  }
}


```

## Restrictions:
-- 

## Known Issues:
  - Height must be >= width or else the rotation animation looks awkward (e.g. it looks awkard if height is width/2)
  - Landscape foreground card is outside of screen?

## TODO:

Feel free to contribute!
