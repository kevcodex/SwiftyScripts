//
//  SlackError.swift
//  Source
//
//  Created by Kevin Chen on 2/20/19.
//

import MiniNe

enum SlackError: Error {
    case invalidURL
    case networkError(MiniNeError)
    case other(message: String)
    case unknown
}
