//
//  Textbox.swift
//  Looomity
//
//  Created by Michael Langbein on 28.12.22.
//

import SwiftUI

extension VStack {
    func textBox() -> some View {
        return self
            .foregroundColor(.primary)
            .padding()
            .background(.gray.opacity(0.2))
            .cornerRadius(15)
            .padding()
    }
}
