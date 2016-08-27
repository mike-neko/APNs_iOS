//
//  PushSender.swift
//  APNs_iOS
//
//  Created by M.Ike on 2016/08/24.
//  Copyright © 2016年 M.Ike. All rights reserved.
//

import Foundation

class PushSender: NSObject, NSURLSessionDelegate, NSURLSessionDataDelegate {
    static let DevServer = "https://api.development.push.apple.com/3/device/"
    static let ProductServer = "https://api.push.apple.com/3/device/"
    
    private let developmentMode: Bool
    private let serverURL: NSURL
    private var clientCredential: NSURLCredential!

    init?(development: Bool, p12URL: NSURL, p12Passphrase: String?) {
        developmentMode = development
    
        guard let url = NSURL(string: development ? PushSender.DevServer : PushSender.ProductServer) else { return nil }
        serverURL = url

        guard let p12data = NSData(contentsOfURL: p12URL) else { return nil }
        
        let options: [String: String]
        if let passphrase = p12Passphrase {
            options = [kSecImportExportPassphrase as String : passphrase]
        } else {
            options = [:]
        }

        var items: CFArray?
        guard SecPKCS12Import(p12data, options, &items) == errSecSuccess else { return nil }
        guard let cfarr = items else { return nil }
        // 証明書の中は単独の前提
        guard let certEntry = (cfarr as Array).first as? [String: AnyObject] else { return nil }
        
        // https://forums.developer.apple.com/thread/11171
        let identity = certEntry["identity"] as! SecIdentity
        let certificates = certEntry["chain"] as? [AnyObject]
        //let trust = certEntry["trust"] as! SecTrustRef
        
        clientCredential = NSURLCredential(identity: identity, certificates: certificates, persistence: .ForSession)
    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge,
                    completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodServerTrust:
            completionHandler(.PerformDefaultHandling, nil)
        case NSURLAuthenticationMethodClientCertificate:
            completionHandler(.UseCredential, clientCredential)
        default:
            completionHandler(.PerformDefaultHandling, nil)
        }
    }

    func send(payload: String, deviceToken: String) {
        let request = NSMutableURLRequest(URL: serverURL.URLByAppendingPathComponent(deviceToken))
        request.HTTPMethod = "POST"
        request.HTTPBody = payload.dataUsingEncoding(NSUTF8StringEncoding)

        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        session.dataTaskWithRequest(request).resume()
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        print("***送信エラー***")
        print(dataTask.response.debugDescription ?? "")
        print(String(data: data, encoding: NSUTF8StringEncoding) ?? "")
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        print("***送信結果***")
        print(task.response.debugDescription ?? "")
        print(error?.description ?? "")
    }
}
