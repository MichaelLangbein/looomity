//
//  PrivacyView.swift
//  Loomity
//
//  Created by Michael Langbein on 11.01.23.
//

import SwiftUI

struct PrivacyView: View {
    var body: some View {
        FullPageView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Loomity does **not collect any user-data** at all.")
                Text("As such, no data is shared with third parties, either.")
                Text("We strongly believe that an app should not collect any user-data that it doesn't need.")
                Text("We also have no servers where any of your data is retained.")
                Text("")
                Text("You can also find our privacy-policy [online](https://codeandcolors.net/loomity/).")
            }
            .textBox()
        }
        .navigationBarTitle("Privacy")
    }
}

struct PrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyView()
    }
}
