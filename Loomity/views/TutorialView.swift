//
//  TutorialView.swift
//  Looomity
//
//  Created by Michael Langbein on 26.12.22.
//

import SwiftUI


struct TutorialPageView<Content: View>: View {
    let content: Content
    let title: String
    @Binding var show: Bool
    
    init(show: Binding<Bool>, title: String = "", @ViewBuilder _ content: () -> Content) {
        self.title = title
        self._show = show
        self.content = content()
    }


    var body: some View {
        VStack(alignment: .center, spacing: 13) {
            HStack {
                Text(self.title)
                    .bold()
                    .foregroundColor(.accentColor)
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
            self.content
            Spacer()
        }
        .textBox()
    }
}


struct ConceptView:  View {
    @Binding var show: Bool

    var body: some View {
        TutorialPageView(show: $show, title: "Welcome!") {
            VStack(alignment: .leading, spacing: 7.5) {
                Text("Loomity is a tool to help you determine the proportions of faces in your photos.")
                Text("It overlays a [Loomis-head](https://gvaat.com/blog/how-to-draw-the-head-using-the-loomis-method-a-step-by-step-guide/) over your photos so that you can compare a face's proportions with a reference.")

            }
            Image("loomified")
                .resizable()
                .padding()
                .scaledToFit()
            Text("It tries to place that model nicely over every face in the image, but you may need to do some **manual adjustment**. The following pages will try to help you do that.")
        }
    }
}

struct SelectView: View {
    @Binding var show: Bool

    var body: some View {
        TutorialPageView(show: $show, title: "Selecting a model") {
            Text("You can select a model by tapping on it.")
            GifView("SelectGif").frame(width: 200, height: 200)
            Text("You can de-select a model again by tapping on the background.")
        }
    }
}

struct RotateView: View {
    @Binding var show: Bool

    var body: some View {
        TutorialPageView(show: $show, title: "Rotating") {
            Text("You can rotate a model by dragging with one finger.")
            GifView("RotateGif").frame(width: 200, height: 200)
        }
    }
}

struct ScaleView: View {
    @Binding var show: Bool

    var body: some View {
        TutorialPageView(show: $show, title: "Scaling") {
            Text("You can scale a model by pinching with two fingers.")
            GifView("ScaleGif").frame(width: 200, height: 200)
            Text("If no model is selected, the whole scene will be scaled instead.")
        }
    }
}

struct TranslateView: View {
    @Binding var show: Bool

    var body: some View {
        TutorialPageView(show: $show, title: "Panning") {
            Text("You can translate a model by panning with two fingers.")
            GifView("PanGif").frame(width: 200, height: 200)
            Text("If no model is selected, the whole scene will be translated instead.")
        }
    }
}

struct ToolsView: View {
    @Binding var show: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        TutorialPageView(show: $show, title: "More tools") {
            Text("There are a few additional tools to help you.")
            Text("")
            
            HStack {
                Text("If loomity did not discover a face in your photo, you can **manually add one**.")
                Image(systemName: "plus.circle")
                                .font(.system(size: 30))
                    .foregroundColor(.accentColor)
            }
            
            HStack {
                Text("You can **re-center** your image to its initial position.")
                Button("Center", action: {}).buttonStyle(.borderedProminent).foregroundColor(.white)
            }

            HStack {
                Text("You can **save** your current view to your photo-gallery.")
                Button("Save image", action: {}).buttonStyle(.borderedProminent).foregroundColor(.white)
            }

        }
    }
}

struct DoneView: View {
    @Binding var show: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TutorialPageView(show: $show, title: "Have fun!") {
            VStack(alignment: .leading, spacing: 7.5) {
                Text("You can always revisit this tutorial by tapping the **?** icon.")

                if colorScheme == .light {
                    Image("ui_cropped2")
                        .resizable()
                        .scaledToFit()
                } else {
                    Image("ui_cropped2_dark")
                        .resizable()
                        .scaledToFit()
                }
                
                Text("That's it! Happy sketching :)")
            }
        }
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
            DoneView(show: $show)
            
        }
        .background(.background)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }
}


struct TutPrev: View {
    @State var show = true
    var body: some View {
//        TutorialView(show: $show)
        ToolsView(show: $show)
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutPrev()
    }
}
