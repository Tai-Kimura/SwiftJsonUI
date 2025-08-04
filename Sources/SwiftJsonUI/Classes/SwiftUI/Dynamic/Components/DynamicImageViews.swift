//
//  DynamicImageViews.swift
//  SwiftJsonUI
//
//  Dynamic image components
//

import SwiftUI

struct DynamicImageView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        Image(component.url ?? "")
            .resizable()
            .aspectRatio(contentMode: DynamicHelpers.contentModeFromString(component.contentMode))
    }
}

struct DynamicNetworkImageView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        NetworkImage(
            url: component.url,
            placeholder: component.placeholder,
            contentMode: DynamicHelpers.networkImageContentMode(component.contentMode),
            renderingMode: DynamicHelpers.renderingModeFromString(component.renderingMode),
            headers: component.headers ?? [:]
        )
    }
}