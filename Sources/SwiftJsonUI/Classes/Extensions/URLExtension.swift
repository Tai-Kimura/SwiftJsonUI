//
//  URLExtension.swift
//  Pods-SwiftJsonUI_Tests
//
//  Created by 木村太一朗 on 2019/09/02.
//

import Foundation

public extension URL {
    func withoutQuery(resolvingAgainstBaseURL: Bool = false) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: resolvingAgainstBaseURL)
        components?.query = nil
        return components?.url
    }
}
