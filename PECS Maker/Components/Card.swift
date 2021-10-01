//
//  Card.swift
//  PECS Maker
//
//  Created by Andy on 01/10/2021.
//
//From: https://www.fivestars.blog/articles/custom-view-styles/

import SwiftUI


extension View {
  func cardStyle<S: CardStyle>(_ style: S) -> some View {
    environment(\.cardStyle, AnyCardStyle(style: style))
  }
}

struct AnyCardStyle: CardStyle {
  private var _makeBody: (Configuration) -> AnyView

  init<S: CardStyle>(style: S) {
    _makeBody = { configuration in
      AnyView(style.makeBody(configuration: configuration))
    }
  }

  func makeBody(configuration: Configuration) -> some View {
    _makeBody(configuration)
  }
}

struct RoundedRectangleCardStyle: CardStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.title)
      .padding()
      .background(RoundedRectangle(cornerRadius: 16).strokeBorder())
  }
}

struct MyRoundedRectangleCardStyle: CardStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      //.font(.title)
      .padding()
      //.background(Theme.cardBackgroundColor)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill((Theme.cardBackgroundColor))
      )
        //RoundedRectangle(cornerRadius: 16).strokeBorder())
  }
}


extension EnvironmentValues {
  var cardStyle: AnyCardStyle {
    get { self[CardStyleKey.self] }
    set { self[CardStyleKey.self] = newValue }
  }
}

struct ShadowCardStyle: CardStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.title)
      .foregroundColor(.black)
      .padding()
      .background(Color.white.cornerRadius(16))
      .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
  }
}

struct CardStyleKey: EnvironmentKey {
  static var defaultValue = AnyCardStyle(style: DefaultCardStyle())
}

struct DefaultCardStyle: CardStyle {
  func makeBody(configuration: Configuration) -> some View {
    #if os(iOS)
      return ShadowCardStyle().makeBody(configuration: configuration)
    #else
      return RoundedRectangleCardStyle().makeBody(configuration: configuration)
    #endif
  }
}

struct CapsuleCardStyle: CardStyle {
  var color: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.title)
      .foregroundColor(.white)
      .padding()
      .background(
        Capsule().fill(color)
      )
      .background(
        Capsule().fill(color.opacity(0.4)).rotationEffect(.init(degrees: -8))
      )
      .background(
        Capsule().fill(color.opacity(0.4)).rotationEffect(.init(degrees: 4))
      )
      .background(
        Capsule().fill(color.opacity(0.4)).rotationEffect(.init(degrees: 8))
      )
      .background(
        Capsule().fill(color.opacity(0.4)).rotationEffect(.init(degrees: -4))
      )
  }
}

struct CardStyleConfiguration {
    /// A type-erased label of a Card.
    struct Label: View {
        init<Content: View>(content: Content) {
            body = AnyView(content)
        }
        
        var body: AnyView
    }
    
    let label: CardStyleConfiguration.Label
}

protocol CardStyle {
    associatedtype Body: View
    typealias Configuration = CardStyleConfiguration
    
    func makeBody(configuration: Self.Configuration) -> Self.Body
}

//struct Card<Content>: View where Content: View {
//    
//    var content: () -> Content
//    
//    init(@ViewBuilder content: @escaping () -> Content) {
//        self.content = content
//    }
//    
//    var body: some View {
//        VStack {
//            content()
//        }
//        //.modifier( CapsuleCardStyle() )
//    }
//}


struct Card<Content>: View where Content: View {
  @Environment(\.cardStyle) var style
  var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }
    
  var body: some View {
    style
      .makeBody(
        configuration: CardStyleConfiguration(
          label: CardStyleConfiguration.Label(content:
            VStack {
                content()
            }
          )
        )
      )
  }
}

