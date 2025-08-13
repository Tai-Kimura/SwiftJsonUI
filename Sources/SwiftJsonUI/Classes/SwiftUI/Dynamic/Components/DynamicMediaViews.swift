//
//  DynamicMediaViews.swift
//  SwiftJsonUI
//
//  Dynamic media and web components
//

import SwiftUI
import WebKit

struct DynamicWebView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        if let urlString = component.url,
           let url = URL(string: urlString) {
            WebViewWrapper(url: url)
                .frame(
                    width: component.width?.asArray.first.flatMap { DynamicHelpers.sizeValue($0) },
                    height: component.height?.asArray.first.flatMap { DynamicHelpers.sizeValue($0) }
                )
        } else {
            Text("Invalid URL")
                .foregroundColor(.gray)
        }
    }
}

struct WebViewWrapper: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op
    }
}

struct DynamicCircleImageView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        Group {
            if let imageName = component.url {
                if imageName.hasPrefix("http") {
                    // Network image
                    DynamicNetworkImageView(component: component, viewModel: viewModel)
                        .clipShape(Circle())
                } else {
                    // Local image
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: contentModeFromString(component.contentMode))
                        .clipShape(Circle())
                        .frame(
                            width: component.width?.asArray.first.flatMap { DynamicHelpers.sizeValue($0) },
                            height: component.height?.asArray.first.flatMap { DynamicHelpers.sizeValue($0) }
                        )
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(
                        width: component.width?.asArray.first.flatMap { DynamicHelpers.sizeValue($0) } ?? 50,
                        height: component.height?.asArray.first.flatMap { DynamicHelpers.sizeValue($0) } ?? 50
                    )
            }
        }
    }
    
    private func contentModeFromString(_ mode: String?) -> ContentMode {
        switch mode?.lowercased() {
        case "fill":
            return .fill
        case "fit":
            return .fit
        default:
            return .fit
        }
    }
}

struct DynamicGradientView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        let colors = gradientColors()
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: gradientStartPoint(),
            endPoint: gradientEndPoint()
        )
        .overlay(
            Group {
                if let children = component.children {
                    VStack(spacing: 0) {
                        ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                            DynamicComponentBuilder(
                                component: child,
                                viewModel: viewModel
                            )
                        }
                    }
                }
            }
        )
    }
    
    private func gradientColors() -> [Color] {
        // Parse gradient colors from items array or use defaults
        if let items = component.items {
            return items.compactMap { DynamicHelpers.colorFromString($0) }
        }
        return [Color.blue, Color.purple]
    }
    
    private func gradientStartPoint() -> UnitPoint {
        // Parse gradient direction or use default
        switch component.orientation?.lowercased() {
        case "horizontal":
            return .leading
        case "vertical":
            return .top
        case "diagonal":
            return .topLeading
        default:
            return .top
        }
    }
    
    private func gradientEndPoint() -> UnitPoint {
        switch component.orientation?.lowercased() {
        case "horizontal":
            return .trailing
        case "vertical":
            return .bottom
        case "diagonal":
            return .bottomTrailing
        default:
            return .bottom
        }
    }
}

struct DynamicBlurView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        ZStack {
            if let children = component.children {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    DynamicComponentBuilder(
                        component: child,
                        viewModel: viewModel
                    )
                }
            }
        }
        .background(
            BlurredBackground(style: blurStyle())
        )
    }
    
    private func blurStyle() -> UIBlurEffect.Style {
        switch component.indicatorStyle?.lowercased() {
        case "light":
            return .light
        case "dark":
            return .dark
        case "extralight":
            return .extraLight
        case "prominent":
            return .prominent
        default:
            return .systemMaterial
        }
    }
}

struct BlurredBackground: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct DynamicTabView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            if let children = component.children {
                ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                    DynamicComponentBuilder(
                        component: child,
                        viewModel: viewModel
                    )
                    .tabItem {
                        if let text = child.text {
                            Label(text, systemImage: child.url ?? "circle")
                        }
                    }
                    .tag(index)
                }
            }
        }
    }
}

struct DynamicSafeAreaView: View {
    let component: DynamicComponent
    @ObservedObject var viewModel: DynamicViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let children = component.children {
                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                    DynamicComponentBuilder(
                        component: child,
                        viewModel: viewModel
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            component.background.flatMap { DynamicHelpers.colorFromString($0) } ?? Color.clear
        )
        .edgesIgnoringSafeArea(.all)
    }
}