//
//  HydeTests.swift
//
//
//  Created by Michael Nisi on 07.04.24.
//

import XCTest
@testable import Hyde

final class HydeTests: XCTestCase {
    func testFetch() async throws {
        let conditions = try await Hyde.fetch()
        
        XCTAssertNotNil(conditions)
        print(conditions)
    }
}
