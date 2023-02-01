//
//  AboutView.swift
//  Looomity
//
//  Created by Michael Langbein on 28.12.22.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        FullPageView {
            VStack {
                Image("michael")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .frame(maxWidth: 200, maxHeight: 200)
                    .opacity(0.8)
                    .saturation(0.9)
                    .shadow(radius: 5)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Loomity was created by Michael Langbein from [code and colors](https://codeandcolors.net).")
                    
                    Text("The Loomis-head model is adjusted from the one provided by [ohsnapitsjoel](https://sketchfab.com/ohsnapitsjoel) on sketchfab:")
                    
                    Link("Loomis-head", destination: URL(string: "https://sketchfab.com/3d-models/loomis-head-d0b3f4aa633a44d8bda8cfe2f779f1f8")!).foregroundColor(.accentColor)
                    
                    Text("under a [creative-commons 4.0](https://creativecommons.org/licenses/by/4.0/) license.")
                    
                }
                .textBox()

            }
        }
        .navigationBarTitle("About")
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
