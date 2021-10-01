/*
 
 https://blog.kaltoun.cz/conditionally-applying-view-modifiers-in-swiftui/
 
 */


import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        }
        else {
            self
        }
    }
}

/*
//Example usage:
 
struct TestView: View {
    @State var isHighlighted = false
    @State var isPadded = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Lorem ipsum dolor sit amet")
                .if(isPadded) { view in
                    view.padding()
                }
                .if(isHighlighted) { view in
                    view.background(Color.yellow)
                }
            
            VStack {
                Button(action: { self.isHighlighted.toggle() }) {
                    Text("Toggle highlight")
                }
                
                Button(action: { self.isPadded.toggle() }) {
                    Text("Toggle padding")
                }
            }
        }
    }
}*/
