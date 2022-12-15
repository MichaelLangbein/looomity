//
//  NavigationView.swift
//  Looomity
//
//  Created by Michael Langbein on 06.11.22.
//

import SwiftUI

struct StartPageView: View {
    
    var body: some View {
        NavigationView {
            VStack {
                SelectImageView()
            }.navigationTitle("Loomity")
        }
    }
}

struct StartPageView_Previews: PreviewProvider {
    static var previews: some View {
        StartPageView()
    }
}
