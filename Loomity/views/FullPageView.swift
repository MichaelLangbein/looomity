//
//  FullPageView.swift
//  Loomity
//
//  Created by Michael Langbein on 06.01.23.
//

import SwiftUI


let backgroundGradient = LinearGradient(
    gradient: Gradient(colors: [.white.opacity(0.0), .accentColor.opacity(0.4)]),
    startPoint: .top,
    endPoint: .bottom
)


struct FullPageView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            backgroundGradient.saturation(0.5)
            content
        }.ignoresSafeArea()
    }
}

struct FullPageView_Previews: PreviewProvider {
    static var previews: some View {
        FullPageView() {
            VStack {
                Text("Testing ...")
            }.textBox()
        }
    }
}
