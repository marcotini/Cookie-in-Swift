//
//  Banana.swift
//  Cookie
//
//  Created by Marco Tini on 2/15/20.
//  Copyright © 2020 Marco Tini. All rights reserved.
//

// https://stackoverflow.com/questions/39772007/wkwebview-persistent-storage-of-cookies

import UIKit
import WebKit

var url = URL(string: "https://google.com")!

class Banana: UIViewController, UIScrollViewDelegate {
    
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
        
        title = "Banana"
        
        // disabilita il pinch to zoom
        self.webView.scrollView.delegate = self
        
        
        var urlRequestCache:NSURLRequest
        if 1==1 {
            urlRequestCache=NSURLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 10)
        }
        else {
            urlRequestCache = NSURLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 60)
        }
        webView.load(urlRequestCache as URLRequest)
        
        
        
        //webView.load(URLRequest(url: url))
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true // torna indietro
        webView.allowsLinkPreview = false // force touch
        
        //webView.load(URLRequest(url: url))
        
        injectToPage()
        
        // tab bar
        let tabArray = tabBarController?.tabBar.items as NSArray?
        let tabItem0 = tabArray?.object(at: 0) as! UITabBarItem
        let tabItem1 = tabArray?.object(at: 1) as! UITabBarItem
        let tabItem2 = tabArray?.object(at: 2) as! UITabBarItem
        let tabItem3 = tabArray?.object(at: 3) as! UITabBarItem
        
        tabItem0.title = "Banana"
        tabItem1.title = "Mango"
        tabItem2.title = "Lettuce"
        tabItem3.title = "Cherry"
        
        
        
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


extension WKWebView {
    
    enum PrefKey {
        static let cookie = "cookies"
    }
    
    func writeDiskCookies(for domain: String, completion: @escaping () -> ()) {
        fetchInMemoryCookies(for: domain) { data in
            print("write data", data)
            UserDefaults.standard.setValue(data, forKey: PrefKey.cookie + domain)
            completion();
        }
    }
    
    
    func loadDiskCookies(for domain: String, completion: @escaping () -> ()) {
        if let diskCookie = UserDefaults.standard.dictionary(forKey: (PrefKey.cookie + domain)) {
            fetchInMemoryCookies(for: domain) { freshCookie in
                print("carico davvero i cookie")
                let mergedCookie = diskCookie.merging(freshCookie) { (_, new) in new }
                
                for (cookieName, cookieConfig) in mergedCookie {
                    let cookie = cookieConfig as! Dictionary<String, Any>
                    
                    var expire : Any? = nil
                    
                    if let expireTime = cookie["Expires"] as? Double{
                        expire = Date(timeIntervalSinceNow: expireTime)
                    }
                    
                    let newCookie = HTTPCookie(properties: [
                        .domain: cookie["Domain"] as Any,
                        .path: cookie["Path"] as Any,
                        .name: cookie["Name"] as Any,
                        .value: cookie["Value"] as Any,
                        .secure: cookie["Secure"] as Any,
                        .expires: expire as Any
                    ])
                    
                    self.configuration.websiteDataStore.httpCookieStore.setCookie(newCookie!)
                }
                
                completion()
            }
            
        } else {
            print("non riesco a caricare i cookie")
            
            completion()
        }
    }
    
    func fetchInMemoryCookies(for domain: String, completion: @escaping ([String: Any]) -> ()) {
        var cookieDict = [String: AnyObject]()
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
            for cookie in cookies {
                if cookie.domain.contains(domain) {
                    cookieDict[cookie.name] = cookie.properties as AnyObject?
                }
            }
            completion(cookieDict)
        }
    }}


// https://stackoverflow.com/questions/39772007/wkwebview-persistent-storage-of-cookies

extension UIViewController: WKUIDelegate, WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        //load cookie of current domain
        print("carico cookie")
        webView.loadDiskCookies(for: url.host!){
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        //write cookie for current domain
        print("scrivo cookie")
        webView.writeDiskCookies(for: url.host!){
            decisionHandler(.allow)
        }
    }
    
}
