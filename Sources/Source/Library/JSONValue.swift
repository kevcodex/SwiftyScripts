//
//  JSONValue.swift
//  Source
//
//  Created by Kevin Chen on 1/4/19.
//

import Foundation

/// Allows decoding of any JSON value
enum JSONValue: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Not a JSON Value"))
        }
    }
    
    func extractValue<T>(for type: T.Type) -> T? {
        switch self {
        case .string(let string):
            return string as? T
        case .int(let int):
            return int as? T
        case .double(let double):
            return double as? T
        case .bool(let bool):
            return bool as? T
        case .object(let object):
            return object as? T
        case .array(let array):
            return array as? T
        }
    }
}
