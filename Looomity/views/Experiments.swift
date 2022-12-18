//
//  Experiments.swift
//  Looomity
//
//  Created by Michael Langbein on 17.12.22.
//

import SwiftUI

struct Experiments: View {
    
    @GestureState var magnifyBy = 1.0

       var magnification: some Gesture {
           MagnificationGesture()
               .updating($magnifyBy) { currentState, gestureState, transaction in
                   gestureState = currentState
               }
       }

       var body: some View {
           Circle()
               .frame(width: 100, height: 100)
               .scaleEffect(magnifyBy)
               .gesture(magnification)
       }
}

struct Experiments_Previews: PreviewProvider {
    static var previews: some View {
        Experiments()
    }
}
