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
        let requestURL = URL(string: "http://failing-url.com")!
        URLProtocolStub.stub(requestURL, with: .failure(URLError(.notConnectedToInternet)))
        let sut = URLSessionHTTPClientAdapter(session: .shared)

        await XCTAssertThrowsErrorAsync(try await sut.execute(HTTPRequest(url: requestURL, method: .get)))
    }

    func test_returnsValueOnSuccess() async throws {
        let requestURL = URL(string: "https://success-with-data.com")!
        let responseData = Data("Hello World".utf8)
        let urlResponse = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        URLProtocolStub.stub(requestURL, with: .success((data: responseData, response: urlResponse)))
        let sut = URLSessionHTTPClientAdapter(session: .shared)

        let response = try await sut.execute(HTTPRequest(url: requestURL, method: .get))

        XCTAssertEqual(response.data, responseData)
        XCTAssertEqual(response.statusCode, 200)
    }

    func test_respectsAllPassedArguments() async throws {
        let sut = URLSessionHTTPClientAdapter(session: .shared)
        let requestURL = URL(string: "http://arguments-test.com")!
        let responseData = Data("Hello World".utf8)
        let urlResponse = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        URLProtocolStub.stub(requestURL, with: .success((data: responseData, response: urlResponse)))

        let json = """
        {
        "key": "value"
        }
        """.utf8

        let response = try await sut.execute(
            HTTPRequest(
                url: requestURL,
                method: .post(body: Data(json)),
                additionalHeaders: [
                    "Content-Type": "application/json"
                ]
            )
        )
        let currentRequest = URLProtocolStub.requests[requestURL]

        XCTAssertNotNil(currentRequest)
        XCTAssertEqual(currentRequest?.httpMethod, HTTPRequest.Method.post(body: Data()).name)
        XCTAssertNotNil(currentRequest?.httpBodyStream)
        XCTAssertEqual(currentRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(URLProtocolStub.readBodyStream(currentRequest!.httpBodyStream!), Data(json))
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.data, responseData)
    }

    func test_returnsInvalidStatusCodeWhenResponseIsNotHttpResponse() async throws {
        let sut = URLSessionHTTPClientAdapter(session: .shared)
        let requestURL = URL(string: "http://wrong-response-type.com")!
        let responseData = Data("Hello World".utf8)
        let urlResponse = URLResponse(url: requestURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)

        URLProtocolStub.stub(requestURL, with: .success((data: responseData, response: urlResponse)))

        let response = try await sut.execute(HTTPRequest(url: requestURL, method: .get))

        XCTAssertEqual(response.data, responseData)
        XCTAssertEqual(response.statusCode, -1)
    }

    func test_shouldCancelRequestWhenParentTaskCanceled() async throws {
        let sut = URLSessionHTTPClientAdapter(session: .shared)
        let requestURL = URL(string: "http://handles-cancellation.com")!

        URLProtocolStub.stub(requestURL, with: .failure(URLError(.badURL)))
        let task = Task {
            try? await sut.execute(HTTPRequest(url: requestURL, method: .get))
        }

        task.cancel()

        let response = await task.value

        XCTAssertNil(response)
        XCTAssertNil(URLProtocolStub.requests[requestURL])
    }
}

// MARK: - Test Helpers

private extension URLSessionHTTPClientAdapterTests {
    class URLProtocolStub: URLProtocol {
        private static var stubs: [URL: Result<(data: Data, response: URLResponse), Error>] = [:]

        static var requests: [URL: URLRequest] = [:]

        static func stub(_ url: URL, with result: Result<(data: Data, response: URLResponse), Error>) {
            stubs[url] = result
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stubs = [:]
            requests = [:]
        }

        static func readBodyStream(_ bodyStream: InputStream) -> Data {
            bodyStream.open()

            let bufferSize = 16

            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

            var data = Data()

            while bodyStream.hasBytesAvailable {
                let readDat = bodyStream.read(buffer, maxLength: bufferSize)
                data.append(buffer, count: readDat)
            }

            buffer.deallocate()

            bodyStream.close()

            return data
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

            URLProtocolStub.requests[url] = request

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
