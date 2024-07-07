//
//  URLSessionHTTPClientAdapterTests.swift
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

@testable import OpenLibraryClient
import XCTest

final class URLSessionHTTPClientAdapterTests: XCTestCase {
    override func setUpWithError() throws {
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDownWithError() throws {
        URLProtocolStub.stopInterceptingRequests()
    }

    func test_throwsErrorWhenNetworkRequestFails() async throws {
        let sut = URLSessionHTTPClientAdapter(session: .shared)
        let requestURL = URL(string: "http://failing-url.com")!
        URLProtocolStub.stub(requestURL, with: .failure(URLError(.notConnectedToInternet)))

        await XCTAssertThrowsErrorAsync(try await sut.execute(HTTPRequest(url: requestURL, method: .get)))
    }
}

// MARK: - Test Helpers

private extension URLSessionHTTPClientAdapterTests {
    class URLProtocolStub: URLProtocol {
        private static var stubs: [URL: Result<(data: Data, response: URLResponse), Error>] = [:]

        static func stub(_ url: URL, with result: Result<(data: Data, response: URLResponse), Error>) {
            stubs[url] = result
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stubs = [:]
        }

        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else {
                return false
            }

            return stubs[url] != nil
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else {
                return
            }

            switch stub {
            case .success(let success):
                client?.urlProtocol(self, didLoad: success.data)
                client?.urlProtocol(self, didReceive: success.response, cacheStoragePolicy: .notAllowed)
            case .failure(let failure):
                client?.urlProtocol(self, didFailWithError: failure)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
