//
//  Experiments.swift
//  Looomity
//
//  Created by Michael Langbein on 17.12.22.
//

import SwiftUI

struct Experiments: View {
    
    @State var count = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1
            }
        }
    }
}

struct Experiments_Previews: PreviewProvider {
    static var previews: some View {
        Experiments()
    }
}
