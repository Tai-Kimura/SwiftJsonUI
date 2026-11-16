//
//  SJUIHostingView.swift
//  SwiftJsonUI
//
//  Base UIView for embedding SwiftUI views in UIKit layouts.
//  Subclass and override makeSwiftUIView() to provide your SwiftUI content.
//  Call updateHostingView() in property didSet to trigger re-render.
//

import UIKit
import SwiftUI

open class SJUIHostingView: SJUIView {
    private let viewModel = HostingViewModel()
    private var hostingController: UIHostingController<HostingWrapperView>?

    @MainActor
    final class HostingViewModel: ObservableObject {
        @Published var content: AnyView = AnyView(EmptyView())
    }

    struct HostingWrapperView: View {
        @ObservedObject var viewModel: HostingViewModel
        var body: some View { viewModel.content }
    }

    /// Override in subclass to return the current SwiftUI view
    open func makeSwiftUIView() -> AnyView {
        AnyView(EmptyView())
    }

    /// Call after property changes to update the embedded SwiftUI view
    public func updateHostingView() {
        viewModel.content = makeSwiftUIView()
        if hostingController == nil {
            let hc = UIHostingController(rootView: HostingWrapperView(viewModel: viewModel))
            hc.view.backgroundColor = .clear
            hc.view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(hc.view)
            NSLayoutConstraint.activate([
                hc.view.topAnchor.constraint(equalTo: topAnchor),
                hc.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                hc.view.trailingAnchor.constraint(equalTo: trailingAnchor),
                hc.view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            hostingController = hc
        }
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        // Find and add hosting controller to parent view controller
        if let hc = hostingController, hc.parent == nil, let parentVC = findViewController() {
            parentVC.addChild(hc)
            hc.didMove(toParent: parentVC)
        }
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController {
                return vc
            }
            responder = next
        }
        return nil
    }
}
