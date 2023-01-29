//
//  Experiments.swift
//  Looomity
//
//  Created by Michael Langbein on 17.12.22.
//

import SwiftUI


struct Experiments: View {

    @State var offset = CGSize(width: 0.0, height: 0.0)
    let twoFingerDrag = DragGesture().simultaneously(with: DragGesture())
    
       var body: some View {
           ZStack {
               Color(.green)
                   .frame(width: 300, height: 300)
                   .offset(offset)
           }
           .background(.gray.opacity(0.001))
           .gesture(twoFingerDrag
            .onChanged { value in
               offset = value.second!.translation
           })
           .border(.red)

               
       }
    
    
}

struct Experiments_Previews: PreviewProvider {
    static var previews: some View {
        Experiments()
    }
}
