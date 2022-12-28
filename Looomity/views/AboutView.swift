//
//  AboutView.swift
//  Looomity
//
//  Created by Michael Langbein on 28.12.22.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Loomity was created by Michael Langbein from [code and colors](https://codeandcolors.net).")
            
            Text("The Loomis-head-model was provided by [ohsnapitsjoel](https://sketchfab.com/ohsnapitsjoel) on sketchfab:")
            
            Link("Loomis-head", destination: URL(string: "https://sketchfab.com/3d-models/loomis-head-b7e2cd611d844df9b69efdc9be6d0215")!).foregroundColor(.blue)
            
            Text("under a [creative-commons 4.0](https://creativecommons.org/licenses/by/4.0/) license.")
            
            Text("This app does not collect any user-data.")

        }
        .textBox()
        .navigationBarTitle("About")
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
