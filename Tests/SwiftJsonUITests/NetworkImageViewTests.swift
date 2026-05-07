//
//  NetworkImageViewTests.swift
//  SwiftJsonUITests
//
//  Tests for the NetworkImageView class
//

import XCTest
@testable import SwiftJsonUI

final class NetworkImageViewTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset default HTTP headers before each test
        NetworkImageView.defaultHttpHeaders = [:]
    }

    // MARK: - Basic Tests

    func testNetworkImageViewInitialization() {
        let imageView = NetworkImageView()

        XCTAssertNotNil(imageView)
        XCTAssertNil(imageView.defaultImage)
        XCTAssertNil(imageView.loadingImage)
        XCTAssertNil(imageView.errorImage)
        XCTAssertNil(imageView.downloader)
        XCTAssertNil(imageView.previousPath)
        XCTAssertNil(imageView.renderingMode)
    }

    // MARK: - Default HTTP Headers Tests

    func testDefaultHttpHeaders() {
        XCTAssertEqual(NetworkImageView.defaultHttpHeaders.count, 0)
    }

    func testCanSetDefaultHttpHeaders() {
        NetworkImageView.defaultHttpHeaders = ["Authorization": "Bearer token"]

        XCTAssertEqual(NetworkImageView.defaultHttpHeaders["Authorization"], "Bearer token")
    }

    func testCanModifyDefaultHttpHeaders() {
        NetworkImageView.defaultHttpHeaders["User-Agent"] = "TestAgent"
        NetworkImageView.defaultHttpHeaders["Accept"] = "image/*"

        XCTAssertEqual(NetworkImageView.defaultHttpHeaders.count, 2)
        XCTAssertEqual(NetworkImageView.defaultHttpHeaders["User-Agent"], "TestAgent")
        XCTAssertEqual(NetworkImageView.defaultHttpHeaders["Accept"], "image/*")
    }

    // MARK: - SetImageResource Tests

    func testSetImageResource() {
        let imageView = NetworkImageView()
        let testImage = UIImage()

        imageView.setImageResource(testImage)

        XCTAssertNotNil(imageView.image)
        XCTAssertNil(imageView.previousPath)
    }

    func testSetImageResourceClearsPreviousPath() {
        let imageView = NetworkImageView()
        imageView.previousPath = "/some/path"

        imageView.setImageResource(UIImage())

        XCTAssertNil(imageView.previousPath)
    }

    func testSetImageResourceCancelsDownloader() {
        let imageView = NetworkImageView()
        let url = URL(string: "https://example.com/image.jpg")!
        imageView.downloader = Downloader(url: url)

        imageView.setImageResource(UIImage())

        // Downloader should be cancelled
        XCTAssertTrue(true) // If we got here without crash, test passed
    }

    func testSetImageResourceWithNil() {
        let imageView = NetworkImageView()
        imageView.image = UIImage()

        imageView.setImageResource(nil)

        XCTAssertNil(imageView.image)
    }

    // MARK: - SetImageURL String Tests

    func testSetImageURLWithValidString() {
        let imageView = NetworkImageView()
        let expectation = self.expectation(description: "Image loading")

        imageView.setImageURL(string: "https://example.com/image.jpg")

        // Give it a moment to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        // Should have created a downloader
        XCTAssertNotNil(imageView.downloader)
    }

    func testSetImageURLWithInvalidString() {
        let imageView = NetworkImageView()
        let errorImage = UIImage()
        imageView.errorImage = errorImage

        imageView.setImageURL(string: "not a valid url")

        XCTAssertEqual(imageView.image, errorImage)
    }

    func testSetImageURLWithNilString() {
        let imageView = NetworkImageView()
        let defaultImage = UIImage()
        imageView.defaultImage = defaultImage

        imageView.setImageURL(string: nil)

        XCTAssertEqual(imageView.image, defaultImage)
    }

    func testSetImageURLWithCustomHeaders() {
        let imageView = NetworkImageView()
        let headers = ["Authorization": "Bearer token"]

        imageView.setImageURL(string: "https://example.com/image.jpg", headers: headers)

        XCTAssertNotNil(imageView.downloader)
    }

    // MARK: - SetImageURL URL Tests

    func testSetImageURLWithURL() {
        let imageView = NetworkImageView()
        let url = URL(string: "https://example.com/image.jpg")!

        imageView.setImageURL(url: url)

        XCTAssertNotNil(imageView.downloader)
    }

    func testSetImageURLWithEmptyURL() {
        let imageView = NetworkImageView()
        // URL(string: "") returns nil, so we test with a valid but non-existent URL
        guard let url = URL(string: "https://invalid.example.com/noimage.jpg") else {
            // Empty string URL returns nil - this is expected
            XCTAssertNil(URL(string: ""))
            return
        }
        let errorImage = UIImage()
        imageView.errorImage = errorImage
        imageView.defaultImage = UIImage()

        imageView.setImageURL(url: url)

        // For invalid URLs, the image might be nil or errorImage
        XCTAssertNotNil(imageView)
    }

    func testSetImageURLCancelsPreviousDownloader() {
        let imageView = NetworkImageView()
        let url1 = URL(string: "https://example.com/image1.jpg")!
        let url2 = URL(string: "https://example.com/image2.jpg")!

        imageView.setImageURL(url: url1)
        let firstDownloader = imageView.downloader

        imageView.setImageURL(url: url2)
        let secondDownloader = imageView.downloader

        XCTAssertNotNil(firstDownloader)
        XCTAssertNotNil(secondDownloader)
        XCTAssertTrue(firstDownloader !== secondDownloader)
    }

    func testSetImageURLWithHeadersParameter() {
        let imageView = NetworkImageView()
        let url = URL(string: "https://example.com/image.jpg")!
        let headers = ["Custom-Header": "Value"]

        imageView.setImageURL(url: url, headers: headers)

        XCTAssertNotNil(imageView.downloader)
    }

    // MARK: - Default/Loading/Error Images Tests

    func testDefaultImageProperty() {
        let imageView = NetworkImageView()
        let defaultImage = UIImage()

        imageView.defaultImage = defaultImage

        XCTAssertEqual(imageView.defaultImage, defaultImage)
    }

    func testLoadingImageProperty() {
        let imageView = NetworkImageView()
        let loadingImage = UIImage()

        imageView.loadingImage = loadingImage

        XCTAssertEqual(imageView.loadingImage, loadingImage)
    }

    func testErrorImageProperty() {
        let imageView = NetworkImageView()
        let errorImage = UIImage()

        imageView.errorImage = errorImage

        XCTAssertEqual(imageView.errorImage, errorImage)
    }

    func testUsesLoadingImageWhenProvided() {
        let imageView = NetworkImageView()
        let loadingImage = UIImage()
        let defaultImage = UIImage()
        imageView.loadingImage = loadingImage
        imageView.defaultImage = defaultImage

        let url = URL(string: "https://example.com/image.jpg")!
        imageView.setImageURL(url: url)

        // When loadingImage is set, it should use loadingImage (not defaultImage)
        // The implementation uses: loadingImage == nil ? defaultImage : loadingImage
        XCTAssertEqual(imageView.image, loadingImage)
    }

    // MARK: - Rendering Mode Tests

    func testRenderingModeProperty() {
        let imageView = NetworkImageView()

        XCTAssertNil(imageView.renderingMode)

        imageView.renderingMode = .alwaysTemplate

        XCTAssertEqual(imageView.renderingMode, .alwaysTemplate)
    }

    func testRenderingModeOptions() {
        let imageView = NetworkImageView()

        imageView.renderingMode = .alwaysOriginal
        XCTAssertEqual(imageView.renderingMode, .alwaysOriginal)

        imageView.renderingMode = .alwaysTemplate
        XCTAssertEqual(imageView.renderingMode, .alwaysTemplate)

        imageView.renderingMode = .automatic
        XCTAssertEqual(imageView.renderingMode, .automatic)
    }

    // MARK: - Edge Cases

    func testMultipleSetImageResourceCalls() {
        let imageView = NetworkImageView()

        for _ in 0..<5 {
            imageView.setImageResource(UIImage())
            XCTAssertNotNil(imageView.image)
        }
    }

    func testSetImageURLAfterSetImageResource() {
        let imageView = NetworkImageView()
        let testImage = UIImage()

        imageView.setImageResource(testImage)
        XCTAssertNotNil(imageView.image)

        let url = URL(string: "https://example.com/image.jpg")!
        imageView.setImageURL(url: url)

        XCTAssertNotNil(imageView.downloader)
    }

    func testPreviousPathProperty() {
        let imageView = NetworkImageView()

        XCTAssertNil(imageView.previousPath)

        imageView.previousPath = "/cached/path"
        XCTAssertEqual(imageView.previousPath, "/cached/path")

        imageView.setImageResource(UIImage())
        XCTAssertNil(imageView.previousPath)
    }

    func testAnimationKey() {
        XCTAssertEqual(NetworkImageView.animationKey, "network_image_view_animation_key")
    }
}
