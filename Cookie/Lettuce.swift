//
//  Lettuce.swift
//  Cookie
//
//  Created by Marco Tini on 2/15/20.
//  Copyright © 2020 Marco Tini. All rights reserved.
//

import UIKit
import WebKit

class Lettuce: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    //MARK: - Activity
    var activityIndicator: UIActivityIndicatorView!
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Lettuce"
        
        // disabilita il pinch to zoom
        self.webView.scrollView.delegate = self
        
        url = URL(string: "https://google.com")!
        
        webView.load(URLRequest(url: url))
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = false
        
        
        injectToPage()
        
        // activity indicator
        
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .gray
        activityIndicator.isHidden = true
        view.addSubview(activityIndicator)
        
    }
    
    //MARK: - UIScrollViewDelegate
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    // 2
    // MARK: - Reading contents of files
    private func readFileBy(name: String, type: String) -> String {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            return "Failed to find path"
        }
        
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            return "Unkown Error"
        }
    }
    
    // 3
    // MARK: - Inject to web page
    func injectToPage() {
        let cssFile = readFileBy(name: "bootstrap-en", type: "css")
        let jsFile = readFileBy(name: "bootstrap", type: "js")
        
        let cssStyle = """
            javascript:(function() {
            var parent = document.getElementsByTagName('head').item(0);
            var style = document.createElement('style');
            style.type = 'text/css';
            style.innerHTML = window.atob('\(encodeStringTo64(fromString: cssFile)!)');
            parent.appendChild(style)})()
        """
        
        let jsStyle = """
            javascript:(function() {
            var parent = document.getElementsByTagName('head').item(0);
            var script = document.createElement('script');
            script.type = 'text/javascript';
            script.innerHTML = window.atob('\(encodeStringTo64(fromString: jsFile)!)');
            parent.appendChild(script)})()
        """
        
        let cssScript = WKUserScript(source: cssStyle, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        let jsScript = WKUserScript(source: jsStyle, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        webView.configuration.userContentController.addUserScript(cssScript)
        webView.configuration.userContentController.addUserScript(jsScript)
    }
    
    // 4
    // MARK: - Encode string to base 64
    private func encodeStringTo64(fromString: String) -> String? {
        let plainData = fromString.data(using: .utf8)
        return plainData?.base64EncodedString(options: [])
    }
}
