//
//  Textbox.swift
//  Looomity
//
//  Created by Michael Langbein on 28.12.22.
//

import SwiftUI

extension VStack {
    func textBox() -> some View {
        modifier(TextBox())
    }
}

extension HStack {
    func textBox() -> some View {
        modifier(TextBox())
    }
}


struct TextBox: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.primary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.gray.opacity(0.2))
//                    .shadow(color: .primary, radius: 3)
            )
            .padding()
    }
}
