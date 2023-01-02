//
//  TutorialView.swift
//  Looomity
//
//  Created by Michael Langbein on 26.12.22.
//

import SwiftUI


struct ConceptView:  View {
    @Binding var show: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 13) {
            HStack {
                Spacer()
                Button(action: {
                    show = false
                }, label: {
                    Image(systemName: "xmark.circle" )
                        .minimumScaleFactor(0.3)
                        .padding(10)
                })
            }
            
            Spacer()
            Text("Loomity is a tool to help you determine the proportions of faces in your photos.")
                .multilineTextAlignment(.center)
            Text("It overlays a [Loomis-head](https://gvaat.com/blog/how-to-draw-the-head-using-the-loomis-method-a-step-by-step-guide/) over your photos so that you can compare a face's proportions with a reference.")
                .multilineTextAlignment(.center)
            Text("It tries to place that model nicely over every face in the image, but you may need to do some manual adjustment. The following pages will try to help you do that.")
                .multilineTextAlignment(.center)
            Spacer()
        }
        .textBox()
    }
}

struct SelectView: View {
    @Binding var show: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 13) {
            HStack {
                Spacer()
                Button(action: {
                    show = false
                }, label: {
                    Image(systemName: "xmark.circle" )
                        .minimumScaleFactor(0.3)
                        .padding(10)
                })
            }
            
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
    @Binding var show: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 13) {
            HStack {
                Spacer()
                Button(action: {
                    show = false
                }, label: {
                    Image(systemName: "xmark.circle" )
                        .minimumScaleFactor(0.3)
                        .padding(10)
                })
            }
            
            Spacer()
            Text("You can rotate a model by dragging with one finger.")
            GifView("RotateGif").frame(width: 200, height: 200)
            Spacer()
        }.textBox()
    }
}

struct ScaleView: View {
    @Binding var show: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 13) {
            HStack {
                Spacer()
                Button(action: {
                    show = false
                }, label: {
                    Image(systemName: "xmark.pcircle" )
                        .minimumScaleFactor(0.3)
                        .padding(10)
                })
            }
            
            Spacer()
            Text("You can scale a model by pinching with two fingers.")
            GifView("ScaleGif").frame(width: 200, height: 200)
            Text("If no model is selected, the whole scene will be scaled instead.")
            Spacer()
        }.textBox()
    }
}

struct TranslateView: View {
    @Binding var show: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 13) {
            HStack {
                Spacer()
                Button(action: {
                    show = false
                }, label: {
                    Image(systemName: "xmark.circle" )
                        .minimumScaleFactor(0.3)
                        .padding(10)
                })
            }
            
            Spacer()
            Text("You can translate a model by panning with two fingers.")
            GifView("PanGif").frame(width: 200, height: 200)
            Text("If no model is selected, the whole scene will be translated instead.")
            Spacer()
        }.textBox()
    }
}

struct ToolsView: View {
    @Binding var show: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Spacer()
                Button(action: {
                    show = false
                }, label: {
                    Image(systemName: "xmark.circle" )
                        .minimumScaleFactor(0.3)
                        .padding(10)
                })
            }

            Spacer()
            Text("You can switch between a perspective and an orthographic view.")
            Text("You can save your current view to your photo-gallery.")
            Spacer()
        }.textBox()
    }
}


struct TutorialView: View {
    
    @Binding var show: Bool
    
    var body: some View {
        TabView {

            ConceptView(show: $show)
            SelectView(show: $show)
            RotateView(show: $show)
            ScaleView(show: $show)
            TranslateView(show: $show)
            ToolsView(show: $show)
            
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
