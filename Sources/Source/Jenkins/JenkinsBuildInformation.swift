//
//  JenkinsBuildInformation.swift
//  TeamMergeAutomation
//
//  Created by Kevin Chen on 1/2/19.
//

import Foundation

struct JenkinsBuildInformation: Decodable {
    let building: Bool
    let description: String
    let fullDisplayName: String
    
    private(set) var parameters: [Parameter]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RootKeys.self)
        
        building = try container.decode(Bool.self, forKey: .building)
        description = try container.decode(String.self, forKey: .description)
        fullDisplayName = try container.decode(String.self, forKey: .fullDisplayName)
        
        // Get the array of actions in container form
        var actionsContainer = try container.nestedUnkeyedContainer(forKey: .actions)
        
        while !actionsContainer.isAtEnd {
            
            // Get the current action container that is being decoded
            let currentActionContainer = try actionsContainer.nestedContainer(keyedBy: ActionKeys.self)
            let string = try currentActionContainer.decodeIfPresent(String.self, forKey: .classString)
            
            guard let classString = string else {
                continue
            }
            
            switch classString {
            case ClassName.parameters:
                // Set the first found value and ignore potential duplicates
                guard self.parameters == nil else {
                    continue
                }
                
                let parameters = try currentActionContainer.decode([Parameter].self, forKey: .parameters)
                self.parameters = parameters
                
            default:
                continue
            }
        }
    }
    
    enum ActionKeys: String, CodingKey {
        case classString = "_class"
        case parameters
    }
    
    enum RootKeys: String, CodingKey {
        case building
        case description
        case fullDisplayName
        case actions
    }
    
    struct ClassName {
        static let parameters = "hudson.model.ParametersAction"
        private init() {}
    }
    
    struct Parameter: Decodable {
        let name: String
        let value: JSONValue
        
        enum Types: String {
            case scheme = "SCHEME"
            case startBuildNumber = "START_BUILD_NUMBER"
        }
    }
    
    func extractValue<T>(for parameterType: Parameter.Types, expectedType: T.Type) -> T? {
        let parameter = parameters?.first(where: { (parameter) -> Bool in
            return parameter.name == parameterType.rawValue
        })
        
        guard let value = parameter?.value else {
            return nil
        }
        
        return value.extractValue(for: expectedType)
    }
}

///// Allows decoding of any JSON value
//enum JSONValue: Decodable {
//    case string(String)
//    case int(Int)
//    case double(Double)
//    case bool(Bool)
//    case object([String: JSONValue])
//    case array([JSONValue])
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        if let value = try? container.decode(String.self) {
//            self = .string(value)
//        } else if let value = try? container.decode(Int.self) {
//            self = .int(value)
//        } else if let value = try? container.decode(Double.self) {
//            self = .double(value)
//        } else if let value = try? container.decode(Bool.self) {
//            self = .bool(value)
//        } else if let value = try? container.decode([String: JSONValue].self) {
//            self = .object(value)
//        } else if let value = try? container.decode([JSONValue].self) {
//            self = .array(value)
//        } else {
//            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Not a JSON Value"))
//        }
//    }
//
//    init?(from any: Any) {
//
//        if let value = any as? String {
//            self = .string(value)
//        } else if let value = any as? Int {
//            self = .int(value)
//        } else if let value = any as? Double {
//            self = .double(value)
//        } else if let value = any as? Bool {
//            self = .bool(value)
//        } else if let value = any as? [String: JSONValue] {
//            self = .object(value)
//        } else if let value = any as? [JSONValue] {
//            self = .array(value)
//        } else {
//            return nil
//        }
//    }
//}
//
//struct JenkinsBuildInformation: Decodable {
//    let building: Bool
//    let description: String
//    let fullDisplayName: String
//
//    private(set) var parameters: [Parameter]?
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: RootKeys.self)
//        building = try container.decode(Bool.self, forKey: .building)
//        description = try container.decode(String.self, forKey: .description)
//        fullDisplayName = try container.decode(String.self, forKey: .fullDisplayName)
//
//        // Get the array of actions in container form
//        var actionsContainer = try container.nestedUnkeyedContainer(forKey: .actions)
//
//        while !actionsContainer.isAtEnd {
//
//            // Get the current action container that is being decoded
//            let currentActionContainer = try actionsContainer.nestedContainer(keyedBy: ActionKeys.self)
//            let string = try currentActionContainer.decodeIfPresent(String.self, forKey: ._class)
//
//            guard let classString = string else {
//                continue
//            }
//
//            switch classString {
//            case "hudson.model.ParametersAction":
//                // Set the first found value and ignore potential duplicates
//                guard self.parameters == nil else {
//                    continue
//                }
//
//                let parameters = try currentActionContainer.decode([Parameter].self, forKey: .parameters)
//                self.parameters = parameters
//
//            default:
//                continue
//            }
//        }
//    }
//
//    init?(dictionary: [String: Any]) {
//
//        guard let building = dictionary["building"] as? Bool else {
//            return nil
//        }
//
//        guard let description = dictionary["description"] as? String else {
//            return nil
//        }
//
//        guard let fullDisplayName = dictionary["fullDisplayName"] as? String else {
//            return nil
//        }
//
//        self.building = building
//        self.description = description
//        self.fullDisplayName = fullDisplayName
//
//        guard let actions = dictionary["actions"] as? [[String: Any]] else {
//            return nil
//        }
//
//        for action in actions {
//            let classString = action["_class"] as? String
//            switch classString {
//            case "hudson.model.ParametersAction":
//                // Set the first found value and ignore potential duplicates
//                guard self.parameters == nil else {
//                    continue
//                }
//
//                guard let parametersDictionary = action["parameters"] as? [[String: Any]] else {
//                    continue
//                }
//
//                var parameters: [Parameter] = []
//
//                for parameter in parametersDictionary {
//                    let name = parameter["name"] as? String
//                    let value = parameter["value"] as Any
//                    let foo = JSONValue(from: value)!
//                    let blah = Parameter(name: name ?? "", value: foo)
//
//                    parameters.append(blah)
//                }
//
//                guard !parameters.isEmpty else {
//                    continue
//                }
//
//                self.parameters = parameters
//
//            default:
//                continue
//            }
//        }
//    }
//
//    enum ActionKeys: String, CodingKey {
//        case _class
//        case parameters
//    }
//
//    enum RootKeys: String, CodingKey {
//        case building
//        case description
//        case fullDisplayName
//        case actions
//    }
//
//    struct Parameter: Decodable {
//        let name: String
//        let value: JSONValue
//    }
//}
