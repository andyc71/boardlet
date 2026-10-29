import SwiftUI
import UIKit

/// Explicit scrolling bounds keep SwiftUI rendering and UIKit hit testing in
/// the same coordinate space, including during safe-area changes on rotation.
struct GridViewport<Content: View>: UIViewControllerRepresentable {
  let contentSize: CGSize
  let focusRect: CGRect?
  @ViewBuilder let content: () -> Content

  func makeUIViewController(context: Context) -> Controller {
    Controller(root: content(), size: contentSize)
  }

  func updateUIViewController(_ controller: Controller, context: Context) {
    controller.host.rootView = content()
    controller.size = contentSize
    controller.focusRect = focusRect
    controller.view.setNeedsLayout()
  }

  final class Controller: UIViewController {
    let scroll = UIScrollView()
    let host: UIHostingController<Content>
    var size: CGSize
    var focusRect: CGRect?
    private var previousFocus: CGRect?
    private var previousSize = CGSize.zero

    init(root: Content, size: CGSize) {
      host = UIHostingController(rootView: root)
      self.size = size
      super.init(nibName: nil, bundle: nil)
      host.safeAreaRegions = []
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
      super.viewDidLoad()
      view.backgroundColor = .clear
      scroll.contentInsetAdjustmentBehavior = .never
      scroll.bounces = false
      scroll.accessibilityIdentifier = "snapGrid"
      view.addSubview(scroll)
      addChild(host)
      host.view.backgroundColor = .clear
      scroll.addSubview(host.view)
      host.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      scroll.frame = view.bounds
      host.view.frame = CGRect(origin: .zero, size: size)
      scroll.contentSize = size
      let maxX = max(0, size.width - scroll.bounds.width)
      let maxY = max(0, size.height - scroll.bounds.height)
      scroll.contentOffset = CGPoint(x: min(maxX, max(0, scroll.contentOffset.x)),
                                     y: min(maxY, max(0, scroll.contentOffset.y)))
      if let focusRect, previousFocus != focusRect || previousSize != scroll.bounds.size {
        scroll.scrollRectToVisible(focusRect, animated: false)
      }
      previousFocus = focusRect
      previousSize = scroll.bounds.size
    }
  }
}
