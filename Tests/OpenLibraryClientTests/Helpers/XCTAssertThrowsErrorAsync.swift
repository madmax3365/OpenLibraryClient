//
//  XCTAssertThrowsErrorAsync.swift
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

import XCTest

/// Asserts that an asynchronous expression throws an error.
/// This function serves as an asynchronous counterpart to `XCTAssertThrowsError`,
/// allowing you to test that an asynchronous expression results in an error.
///
/// Example usage:
/// ```swift
///     await XCTAssertThrowsErrorAsync(
///         try await sut.method()
///     ) { error in
///         XCTAssertEqual(error as? SomeError, SomeError.specificError)
///     }
/// ```
///
/// - Parameters:
///   - expression: An asynchronous expression that is expected to throw an error.
///   - message: An optional description to display if the assertion fails. This can help
///     provide more context about the failure.
///   - file: The file in which the failure occurs. By default, this is set to the filename
///     of the test case where this function is called.
///   - line: The line number on which the failure occurs. By default, this is set to the line
///     number where this function is called.
///   - errorHandler: An optional closure to handle the error thrown by the expression.
///     This allows you to perform additional assertions or actions based on the specific error.
func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "Execution didn't throw an error",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: any Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
