//
//  WebConverter.swift
//  SwiftJsonUI
//
//  Converts DynamicComponent to SwiftUI WebView
//

import SwiftUI

public struct WebConverter {
    
    /// Convert DynamicComponent to SwiftUI WebView
    public static func convert(
        component: DynamicComponent,
        viewModel: DynamicViewModel
    ) -> AnyView {
        guard let urlString = component.src,
              let url = URL(string: urlString) else {
            return AnyView(
                Text("Invalid URL")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .modifier(CommonModifiers(component: component, viewModel: viewModel))
            )
        }
        
        // Use existing SwiftJsonUI WebView
        return AnyView(
            WebView(url: url)
                .frame(width: component.width, height: component.height)
                .modifier(CommonModifiers(component: component, viewModel: viewModel))
        )
    }
}