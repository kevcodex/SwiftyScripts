//
//  XMLParserService.swift
//  Source
//
//  Created by Kevin Chen on 12/26/18.
//

import Foundation

enum XMLParserServiceError: Error {
    case empty
    case parseError(Error)
    case unknown
}
/**
 - Example:
 ```
 // Data is xml with header: defaultCrumbIssuer and two keys crumb and crumbRequestField
 let test = XMLParserService(header: "defaultCrumbIssuer",
                            keys: ["crumb", "crumbRequestField"])
 test.parse(data: data, completion: { (test) in
    print(test)
 }
 */
class XMLParserService: NSObject, XMLParserDelegate {
    
    private var context: XMLContext
    
    private var parser: XMLParser?
    
    // Outputs
    private var responseDictionary: [String: Any] = [:]
    private var error: XMLParserServiceError?
    
    private var response: Result<[String: Any], XMLParserServiceError>?
    
    init(header: String, keys: [String]) {
        self.context = XMLContext(header: header,
                                  keys: keys,
                                  currentElementName: nil,
                                  shouldParse: false)
    }
    
    func parse(data: Data, completion: (Result<[String: Any], XMLParserServiceError>) -> Void) {
        
        parser = XMLParser(data: data)
        parser?.delegate = self
        
        if let _ = parser?.parse() {
            
            if let dictionary = responseDictionary.nonEmpty {
                completion(Result(value: dictionary))
            } else {
                completion(Result(error: .empty))
            }
            
        } else if let error = self.error {
            completion(Result(error: error))
        } else {
            completion(Result(error: .unknown))
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if context.keys.contains(elementName) {
            context.currentElementName = elementName
            context.shouldParse = true
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if context.shouldParse,
            let key = context.currentElementName {
            
            responseDictionary[key] = string
            
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // reset context
        context.currentElementName = nil
        context.shouldParse = false
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.error = .parseError(parseError)
    }
}

struct XMLContext {
    let header: String
    let keys: [String]
    
    var currentElementName: String?
    var shouldParse: Bool
}
