//
//  BlinkButtonView.swift
//  Loomity
//
//  Created by Michael Langbein on 05.02.23.
//

import SwiftUI


struct BlinkView<Content: View>: View {
    let content: Content
    @State var blinking = false
    
    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .brightness(blinking ? 0.2 : 0.0)
//            .shadow(color: .white, radius: blinking ? 5 : 0)
            .animation(.default.repeatForever().speed(0.125), value: blinking)
            .onAppear {
                blinking.toggle()
            }
    }
}

struct BlinkButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VStack {
//                NavigationLink(destination: ProductsView()) {
//                    Text("Click me").foregroundColor(.white)
//                }.buttonStyle(.borderedProminent)
                
                BlinkView {
                    NavigationLink(destination: ProductsView()) {
                        Text("Click me")
                    }
//                    Button {
//
//                    } label: {
//                        Text("Click me")
//                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.white)
                }

            }
        }
    }
}
