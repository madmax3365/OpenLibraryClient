//
//  URLSessionHTTPClientAdapter.swift
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

final class URLSessionHTTPClientAdapter: HTTPClient {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    /// Executes the provided request
    /// - Parameter request: The request to be made
    /// - Returns: `HTTPResponse` containing data and statusCode
    /// - Throws: This method will throw an error in any situation where `URLSession.data(for:)` would also throw one, as the request is handled by `URLSession`.
    func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
        let urlRequest = urlRequest(from: request)
        let (data, response) = try await session.data(for: urlRequest)
        return httpResponse(from: response, data: data)
    }

    /// Converts `HTTPRequest` into `URLRequest`
    /// - Parameter request: The incoming `HTTPRequest`
    /// - Returns: Configured `URLRequest`
    private func urlRequest(from request: HTTPRequest) -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.name
        if case .post(let body) = request.method {
            urlRequest.httpBody = body
        }

        for header in request.additionalHeaders {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        return urlRequest
    }

    /// Converts `URLResponse` into `HTTPResponse`
    /// - Parameters:
    ///   - response: The received `URLResponse`
    ///   - data: Raw data from Network
    /// - Returns: `HTTPResponse` containing data and status code
    /// - Note: If for some reason the response fails to downcast into `HTTPURLResponse` ,
    /// the `statusCode` of `HTTPResponse` will be set to `-1`
    private func httpResponse(from response: URLResponse, data: Data) -> HTTPResponse {
        guard let response = response as? HTTPURLResponse else {
            return HTTPResponse(data: data, statusCode: -1)
        }

        return HTTPResponse(data: data, statusCode: response.statusCode)
    }
}
