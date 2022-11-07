//
//  NavigationView.swift
//  Looomity
//
//  Created by Michael Langbein on 06.11.22.
//

import SwiftUI

struct StartPage: View {
    @State var showHelp = false
    
    var body: some View {
        NavigationView {
            VStack {
                ContentView()
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .navigationTitle("Loomity")
            .toolbar {
                Button {
                    showHelp = true
                } label: {
                    Label("Help", systemImage: "questionmark.circle")
                }
            }
        }
    }
}

struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        StartPage()
    }
}
