//
//  TrialView.swift
//  Looomity
//
//  Created by Michael Langbein on 28.12.22.
//

import SwiftUI

struct TrialView: View {
    var body: some View {
        VStack {
            Text("You're viewing the free trial of loomity.")
            Text("Days remaining: 7.")
            Button("Buy now", action: {}).buttonStyle(.borderedProminent)
        }.textBox()
    }
}

struct TrialView_Previews: PreviewProvider {
    static var previews: some View {
        TrialView()
    }
}
