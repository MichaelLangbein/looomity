//
//  GifView.swift
//  Looomity
//
//  Created by Michael Langbein on 27.12.22.
//

import SwiftUI
import WebKit

struct GifView: UIViewRepresentable {
    
    private var fileName: String
    
    init(_ fileName: String) {
        self.fileName = fileName
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        let url = Bundle.main.url(forResource: fileName, withExtension: "gif")!
        let data = try! Data(contentsOf: url)
        view.load(data, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: url.deletingLastPathComponent())
        
        view.isOpaque = false
        view.backgroundColor = UIColor.clear
        view.scrollView.backgroundColor = UIColor.clear
        view.scrollView.isScrollEnabled = false
        view.allowsBackForwardNavigationGestures = false
        view.allowsLinkPreview = false
        
        return view
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
