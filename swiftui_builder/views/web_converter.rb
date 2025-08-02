#!/usr/bin/env ruby

require_relative 'base_view_converter'

class WebConverter < BaseViewConverter
  def convert
    url = @component['url'] || "https://example.com"
    
    # WebViewはSwiftUIでは直接サポートされていないため、
    # UIViewRepresentableを使用する必要があることを示す
    add_line "// WebView requires UIViewRepresentable implementation"
    add_line "WebView(url: URL(string: \"#{url}\")!)"
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    # WebView実装の注記
    add_line ""
    add_line "// Note: Add this WebView implementation to your project:"
    add_line "/*"
    add_line "struct WebView: UIViewRepresentable {"
    add_line "    let url: URL"
    add_line "    "
    add_line "    func makeUIView(context: Context) -> WKWebView {"
    add_line "        return WKWebView()"
    add_line "    }"
    add_line "    "
    add_line "    func updateUIView(_ webView: WKWebView, context: Context) {"
    add_line "        let request = URLRequest(url: url)"
    add_line "        webView.load(request)"
    add_line "    }"
    add_line "}"
    add_line "*/"
    
    generated_code
  end
end