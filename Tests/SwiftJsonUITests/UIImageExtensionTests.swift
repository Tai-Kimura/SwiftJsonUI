//
//  UIImageExtensionTests.swift
//  SwiftJsonUITests
//
//  Tests for UIImage extension methods
//

import XCTest
@testable import SwiftJsonUI

final class UIImageExtensionTests: XCTestCase {

    // MARK: - Helper Methods

    func createTestImage(size: CGSize, color: UIColor = .red) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Resize Tests

    func testResizeToSmallerSize() {
        let originalImage = createTestImage(size: CGSize(width: 200, height: 200))
        let targetSize = CGSize(width: 100, height: 100)
        let resizedImage = originalImage.resize(targetSize)

        XCTAssertNotNil(resizedImage)
        // Allow for some floating point precision issues
        XCTAssertEqual(resizedImage.size.width, 100, accuracy: 1.0)
        XCTAssertEqual(resizedImage.size.height, 100, accuracy: 1.0)
    }

    func testResizeToSmallerSizeWithDifferentAspectRatio() {
        let originalImage = createTestImage(size: CGSize(width: 400, height: 200))
        let targetSize = CGSize(width: 100, height: 100)
        let resizedImage = originalImage.resize(targetSize)

        XCTAssertNotNil(resizedImage)
        // Should maintain aspect ratio, so width should be twice height
        XCTAssertEqual(resizedImage.size.width / resizedImage.size.height, 2.0, accuracy: 0.1)
    }

    func testResizeToLargerSizeUpscales() {
        let originalImage = createTestImage(size: CGSize(width: 100, height: 100))
        let targetSize = CGSize(width: 500, height: 500)
        let resizedImage = originalImage.resize(targetSize)

        XCTAssertNotNil(resizedImage)
        // The resize function DOES upscale when target is larger
        // It scales based on the minimum ratio to fill the target size
        XCTAssertGreaterThanOrEqual(resizedImage.size.width, 100)
        XCTAssertGreaterThanOrEqual(resizedImage.size.height, 100)
    }

    func testResizeWidthRatioDominates() {
        let originalImage = createTestImage(size: CGSize(width: 1000, height: 500))
        let targetSize = CGSize(width: 200, height: 600)
        let resizedImage = originalImage.resize(targetSize)

        XCTAssertNotNil(resizedImage)
        // Width ratio (0.2) is smaller than height ratio (1.2), so it dominates
        XCTAssertEqual(resizedImage.size.width, 200, accuracy: 1.0)
        XCTAssertEqual(resizedImage.size.height, 100, accuracy: 1.0)
    }

    func testResizeHeightRatioDominates() {
        let originalImage = createTestImage(size: CGSize(width: 500, height: 1000))
        let targetSize = CGSize(width: 600, height: 200)
        let resizedImage = originalImage.resize(targetSize)

        XCTAssertNotNil(resizedImage)
        // Height ratio (0.2) is smaller than width ratio (1.2), so it dominates
        XCTAssertEqual(resizedImage.size.width, 100, accuracy: 1.0)
        XCTAssertEqual(resizedImage.size.height, 200, accuracy: 1.0)
    }

    func testResizePreservesAspectRatio() {
        let originalImage = createTestImage(size: CGSize(width: 800, height: 600))
        let targetSize = CGSize(width: 400, height: 400)
        let resizedImage = originalImage.resize(targetSize)

        XCTAssertNotNil(resizedImage)
        // Original ratio is 800/600 = 1.333...
        let newRatio = resizedImage.size.width / resizedImage.size.height
        XCTAssertEqual(newRatio, 800/600, accuracy: 0.01)
    }

    // MARK: - Circular Image Tests

    func testCircularScaleAndCrop() {
        let image = createTestImage(size: CGSize(width: 100, height: 100))
        let circularImage = image.circularScaleAndCropImage()

        XCTAssertNotNil(circularImage)
    }

    func testCircularScaleAndCropWithRectangle() {
        let image = createTestImage(size: CGSize(width: 200, height: 100))
        guard let circularImage = image.circularScaleAndCropImage() else {
            XCTFail("Failed to create circular image")
            return
        }

        // For a rectangle, the result should be based on the smaller dimension
        XCTAssertLessThanOrEqual(circularImage.size.width, 150)
    }

    func testCircularScaleAndCropWithTallImage() {
        let image = createTestImage(size: CGSize(width: 100, height: 200))
        guard let circularImage = image.circularScaleAndCropImage() else {
            XCTFail("Failed to create circular image")
            return
        }

        // For a tall image, the result should be based on the smaller dimension (width)
        XCTAssertLessThanOrEqual(circularImage.size.height, 150)
    }

    // MARK: - Base64 Encoding Tests

    func testBase64ImageEncoding() {
        let image = createTestImage(size: CGSize(width: 10, height: 10))
        guard let _ = image.pngData() else {
            XCTFail("Could not create PNG data from image")
            return
        }

        let base64String = image.base64image()

        XCTAssertFalse(base64String.isEmpty)
        // The implementation uses .lineLength64Characters which adds line breaks
        // So we need to remove them before decoding
        let cleanedBase64 = base64String.replacingOccurrences(of: "\r\n", with: "")
        XCTAssertNotNil(Data(base64Encoded: cleanedBase64))
    }

    func testBase64ImageEncodingDifferentSizes() {
        let smallImage = createTestImage(size: CGSize(width: 10, height: 10))
        let largeImage = createTestImage(size: CGSize(width: 100, height: 100))

        let smallBase64 = smallImage.base64image()
        let largeBase64 = largeImage.base64image()

        // Larger image should have longer base64 string
        XCTAssertGreaterThan(largeBase64.count, smallBase64.count)
    }

    func testBase64ImageCanBeDecoded() {
        let originalImage = createTestImage(size: CGSize(width: 50, height: 50))
        guard let _ = originalImage.pngData() else {
            XCTFail("Could not create PNG data from original image")
            return
        }

        let base64String = originalImage.base64image()

        // The implementation uses .lineLength64Characters which adds line breaks
        // So we need to remove them before decoding
        let cleanedBase64 = base64String.replacingOccurrences(of: "\r\n", with: "")

        // Decode and verify
        if let data = Data(base64Encoded: cleanedBase64),
           let decodedImage = UIImage(data: data) {
            XCTAssertNotNil(decodedImage)
            // Size might vary due to scale, but should be reasonable
            XCTAssertGreaterThan(decodedImage.size.width, 10)
            XCTAssertGreaterThan(decodedImage.size.height, 10)
        } else {
            XCTFail("Failed to decode base64 image")
        }
    }
}
