//
import Foundation

import UIKit

import UIKit

class Progress: NSObject {
    
    static var view = UIView()
    
    static var dismissButton = UIButton(type: UIButtonType.custom)
    static var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    static var messageView = UITextView()
    static var progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.bar)
    
    func onCancel(){
        Progress.hide()
    }

    static func show(_ vc: UIViewController)
    {
        show(vc, message: "Operation in progress\nPlease wait...", progress: false)
    }
    
    static func show(_ vc: UIViewController, message: String)
    {
        show(vc, message: message, progress: false)
    }

    static func centerRect(_ width: CGFloat, height: CGFloat, top: CGFloat) -> CGRect
    {
        let bounds=UIScreen.main.bounds
        var t = top
        if t == -1
        {
            t = bounds.height/2-height/2
        }
        return CGRect(x: bounds.width/2-width/2, y: t, width: width, height: height)
    }

    static func show(_ vc: UIViewController, message: String, progress: Bool)
    {
        let bounds=UIScreen.main.bounds

        view = UIView(frame: bounds)

        // Build a programmatic view
        view.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.9)

        //add activity indicator
        activityIndicator.frame = centerRect(40, height: 40, top: -1)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()

        //add text message (if any)
        messageView.frame=centerRect(bounds.width-40, height: 200, top: bounds.height/2-200)
        messageView.textAlignment = .center
        messageView.backgroundColor=UIColor.clear
        messageView.font=UIFont(name: "Helvetica", size: 24)
        messageView.text = message
        view.addSubview(messageView)

        //add progress (if any)
        progressView.frame=centerRect(bounds.width-40, height: 40, top: (bounds.height/4)*3)
        progressView.setProgress(0, animated: false)
        view.addSubview(progressView)

        //add the done button
        dismissButton.setTitle("Done", for: UIControlState())
        dismissButton.titleLabel!.font = UIFont(name: "Helvetica", size: 24)
        dismissButton.titleLabel!.textAlignment = .left
        dismissButton.frame = centerRect(400, height: 200, top: bounds.height-400)
        dismissButton.addTarget(self, action: #selector(Progress.onCancel), for: .touchUpInside)
        //        view.addSubview(dismissButton)


        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.addSubview(view)

        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    }
    
    static func hide()
    {
        activityIndicator.stopAnimating()

        view.removeFromSuperview()
    }
    
    static func setMessage(_ message: String)
    {
        messageView.text=message
    }
    
    static func setProgress(_ percents: Float)
    {
        progressView.setProgress(percents/100.0, animated: false)
    }
}
