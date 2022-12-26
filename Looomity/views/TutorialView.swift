//
//  TutorialView.swift
//  Looomity
//
//  Created by Michael Langbein on 26.12.22.
//

import SwiftUI

struct TutorialView: View {
    
    @Binding var show: Bool
//    @State var alreadySeenOnce = UserDefaults.standard.value(forKey: "UserHasSeenOnboarding")
    
    var body: some View {
        TabView {
            Text("first")
            Text("second")
            Button("Get started") {
                show = false
            }
        }
        .tabViewStyle(.page)
//        .onAppear() {
//            UserDefaults.standard.setValue(true, forKey: "UserHasSeenOboarding")
//        }
    }
}


struct TutPrev: View {
    @State var show = true
    var body: some View {
        TutorialView(show: $show)
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutPrev()
    }
}
