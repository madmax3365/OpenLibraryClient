//
//  HTTPRequest.swift
//  OpenLibrary
//
//  Created by Gagik Muradyan on 07.07.24.
//
//  Copyright © 2024 Gagik Muradyan.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Foundation

/// A model representing an HTTP request
struct HTTPRequest: Sendable {
    typealias HTTPHeader = [String: String?]

    /// HTTP URL to make request to
    var url: URL

    /// HTTP method
    var method: Method

    /// Additional HTTP headers to append to the request
    var additionalHeaders: [HTTPHeader]
}

// MARK: - Sub-types

extension HTTPRequest {
    /// An enum Representation of HTTP request methods
    enum Method {
        /// HTTP GET method
        case get

        /// HTTP POST method
        /// - Parameter body: Encoded body to send with the request
        case post(body: Data)

        /// The canonical HTTP name for the method
        var name: String {
            switch self {
            case .get:
                "GET"
            case .post:
                "POST"
            }
        }
    }
}
