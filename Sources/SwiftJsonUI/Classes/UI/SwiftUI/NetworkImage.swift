//
//  NetworkImage.swift
//  SwiftJsonUI
//
//  SwiftUI implementation of network image loading
//

import SwiftUI

public struct NetworkImage: View {
    let url: String?
    let placeholder: String?
    let contentMode: ContentMode
    let renderingMode: Image.TemplateRenderingMode?
    let headers: [String: String]
    
    public enum ContentMode {
        case fit
        case fill
        case center
    }
    
    public init(
        url: String? = nil,
        placeholder: String? = nil,
        contentMode: ContentMode = .fit,
        renderingMode: Image.TemplateRenderingMode? = nil,
        headers: [String: String] = [:]
    ) {
        self.url = url
        self.placeholder = placeholder
        self.contentMode = contentMode
        self.renderingMode = renderingMode
        self.headers = headers
    }
    
    public var body: some View {
        if let urlString = url, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    // ローディング中
                    if let placeholder = placeholder {
                        Image(placeholder)
                            .resizable()
                            .renderingMode(renderingMode)
                            .aspectRatio(contentMode: contentModeToSwiftUI())
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                case .success(let image):
                    // 成功
                    image
                        .resizable()
                        .renderingMode(renderingMode)
                        .aspectRatio(contentMode: contentModeToSwiftUI())
                case .failure(_):
                    // エラー
                    if let placeholder = placeholder {
                        Image(placeholder)
                            .resizable()
                            .renderingMode(renderingMode)
                            .aspectRatio(contentMode: contentModeToSwiftUI())
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            // URLが無効な場合
            if let placeholder = placeholder {
                Image(placeholder)
                    .resizable()
                    .renderingMode(renderingMode)
                    .aspectRatio(contentMode: contentModeToSwiftUI())
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func contentModeToSwiftUI() -> SwiftUI.ContentMode {
        switch contentMode {
        case .fit:
            return .fit
        case .fill:
            return .fill
        case .center:
            return .fit  // SwiftUIには.centerがないので.fitで代用
        }
    }
}

// カスタムAsyncImageローダー（ヘッダー対応が必要な場合）
@available(iOS 15.0, *)
public struct NetworkAsyncImage: View {
    let url: URL?
    let headers: [String: String]
    let contentMode: SwiftUI.ContentMode
    let placeholder: AnyView?
    let errorView: AnyView?
    
    @State private var imageData: Data?
    @State private var isLoading = false
    @State private var hasError = false
    
    public init(
        url: URL?,
        headers: [String: String] = [:],
        contentMode: SwiftUI.ContentMode = .fit,
        @ViewBuilder placeholder: () -> some View = { ProgressView() },
        @ViewBuilder errorView: () -> some View = { Image(systemName: "photo").foregroundColor(.gray) }
    ) {
        self.url = url
        self.headers = headers
        self.contentMode = contentMode
        self.placeholder = AnyView(placeholder())
        self.errorView = AnyView(errorView())
    }
    
    public var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                placeholder
            } else if hasError {
                errorView
            } else {
                placeholder
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url else {
            hasError = true
            return
        }
        
        isLoading = true
        hasError = false
        
        var request = URLRequest(url: url)
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data, error == nil {
                    imageData = data
                } else {
                    hasError = true
                }
            }
        }.resume()
    }
}

// MARK: - Preview
struct NetworkImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Network Image Examples")
                .font(.headline)
            
            NetworkImage(
                url: "https://via.placeholder.com/150",
                contentMode: .fit
            )
            .frame(width: 150, height: 150)
            .background(Color.gray.opacity(0.2))
            
            NetworkImage(
                url: "https://invalid-url",
                placeholder: "placeholder_image",
                contentMode: .fill
            )
            .frame(width: 150, height: 100)
            .clipped()
            .background(Color.gray.opacity(0.2))
        }
        .padding()
    }
}