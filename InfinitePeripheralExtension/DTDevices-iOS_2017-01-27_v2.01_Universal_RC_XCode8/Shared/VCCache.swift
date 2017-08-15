import Foundation
import UIKit

class VCCache {
    static var cachedViewControllers = Dictionary<String, UIViewController>()
    
    class func getViewController(_ storyBoard: UIStoryboard?, name: String) -> UIViewController
    {
        var vc=cachedViewControllers[name]
        if vc == nil
        {
            vc = storyBoard!.instantiateViewController(withIdentifier: name)
            cachedViewControllers[name]=vc
        }
        return vc!
    }
}
