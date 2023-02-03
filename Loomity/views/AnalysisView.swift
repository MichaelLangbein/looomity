//
//  AnalysisWrapper.swift
//  Looomity
//
//  Created by Michael Langbein on 15.12.22.
//

import SwiftUI
import Vision


enum AnalysisState {
    case ongoing, done
}

struct AnalysisView: View {
    
    let image: UIImage
    @State var showHelp = false
    
    var body: some View {
        HeadControllerView(image: image)
    }
}

struct AnalysisWrapper_Previews: PreviewProvider {
    static var previews: some View {
        let img = UIImage(named: "TestImage2")!
        AnalysisView(image: img)
    }
}
