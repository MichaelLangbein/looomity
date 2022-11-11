//
//  HelpView.swift
//  Looomity
//
//  Created by Michael Langbein on 06.11.22.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Text("Pan with one finger to rotate the camera around the scene.")
            Text("Pan with two fingers to translate the camera on its local xy-plane.")
            Text("Pan with three fingers vertically to move the camera forward and backward.")
            Text("Double-tap to switch to the next camera in the scene.")
            Text("Rotate with two fingers to roll the camera (rotate on the camera node's z-axis).")
            Text("Pinch to zoom in or zoom out (change the camera's fieldOfView).")
        }.navigationTitle("Help")
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
