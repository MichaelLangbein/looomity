//
//  TutorialView.swift
//  Looomity
//
//  Created by Michael Langbein on 26.12.22.
//

import SwiftUI


struct ConceptView:  View {
    var body: some View {
        VStack (alignment: .center, spacing: 9) {
            Text("Loomity is a tool to help you determine the proportions of faces in your photos.")
                .multilineTextAlignment(.center)
            Text("It overlays a [Loomis-head](https://gvaat.com/blog/how-to-draw-the-head-using-the-loomis-method-a-step-by-step-guide/) over your photo's so that you can compare a face's proportions with a reference.")
                .multilineTextAlignment(.center)
        }
        .textBox()
    }
}

struct SelectView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("You can select a model by tapping on it.")
            GifView("SelectGif").frame(width: 200, height: 200)
            Text("You can de-select a model again by tapping on the background.")
            Spacer()
        }
        .textBox()
        .navigationTitle("Selection")
    }
}

struct RotateView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("You can rotate a model by dragging with one finger.")
            GifView("RotateGif").frame(width: 200, height: 200)
            Spacer()
        }.textBox()
    }
}

struct ScaleView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("You can scale a model by pinching with two fingers.")
            GifView("ScaleGif").frame(width: 200, height: 200)
            Spacer()
        }.textBox()
    }
}

struct TranslateView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("You can translate a model by panning with two fingers.")
            GifView("PanGif").frame(width: 200, height: 200)
            Text("If no model is selected, the whole scene will be translated instead.")
            Spacer()
        }.textBox()
    }
}

struct ToolsView: View {
    var body: some View {
        VStack {
            Text("You can switch between a perspective and an orthographic view.")
            Text("You can save your current view to your gallery.")
        }.textBox()
    }
}


struct TutorialView: View {
    
    @Binding var show: Bool
    
    var body: some View {
        TabView {

            ConceptView()
            SelectView()
            RotateView()
            ScaleView()
            TranslateView()
            ToolsView()
            
            Button("Get started") {
                show = false
            }.buttonStyle(.borderedProminent)
            
        }
        .background(Color.white)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
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
