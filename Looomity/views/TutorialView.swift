//
//  TutorialView.swift
//  Looomity
//
//  Created by Michael Langbein on 26.12.22.
//

import SwiftUI



struct WelcomeView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to Loomity!")
            Image("nobackground")
                .resizable()
                .frame(width: 300, height: 300)
            Text("Loomity is a tool to help you determine the proportions of faces in your photos.")
            Spacer()
        }
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
        }.navigationTitle("Selection")
    }
}

struct RotateView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("You can rotate a model by dragging with one finger.")
            GifView("RotateGif").frame(width: 200, height: 200)
            Spacer()
        }
    }
}

struct ScaleView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("You can scale a model by pinching with two fingers.")
            GifView("ScaleGif").frame(width: 200, height: 200)
            Spacer()
        }
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
        }
    }
}

struct ToolsView: View {
    var body: some View {
        VStack {
            Text("You can switch between a perspective and an orthographic view.")
            Text("You can save your current view to your gallery.")
        }
    }
}


struct TutorialView: View {
    
    @Binding var show: Bool
    var withIntro = true
    
    var body: some View {
        TabView {
            
            if withIntro {
                WelcomeView()
            }
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
