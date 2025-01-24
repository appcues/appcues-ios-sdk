//
//  SwizzlerTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2025-01-24.
//  Copyright © 2025 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

final class SwizzlerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @available(iOS 13.0, *)
    func testDelegateSubclassSwizzlingInfiniteLoop() throws {
        // Arrange
        let scrollView = UIScrollView()
        let delegate1 = ScrollViewDelegate1()
        let delegate2 = ScrollViewDelegate2()

        // Act
        UIScrollView.swizzleScrollViewGetDelegate()
        scrollView.delegate = delegate1
        scrollView.delegate = delegate2

        // Assert
        let swizzledDelegateMethod = try XCTUnwrap(scrollView.delegate?.scrollViewWillBeginDragging)
        // This shouldn't loop forever!
        swizzledDelegateMethod(scrollView)
    }
}

private extension SwizzlerTests {
    class ScrollViewDelegate1: NSObject, UIScrollViewDelegate {}
    class ScrollViewDelegate2: ScrollViewDelegate1 {}
}
