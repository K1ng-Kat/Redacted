import SwiftUI
import UIKit

/// Prevents elastic overscroll on the HQ page without preventing scrolling.
/// The marker lives INSIDE that page's ScrollView, so its ancestor search
/// affects only this one UIScrollView (not Settings or puzzle controls).
struct HomeScrollBounceLock: UIViewRepresentable {
    func makeUIView(context: Context) -> BounceMarkerView {
        let view = BounceMarkerView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: BounceMarkerView, context: Context) {
        uiView.lockEnclosingScrollView()
    }
}

final class BounceMarkerView: UIView {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        lockEnclosingScrollView()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        lockEnclosingScrollView()
    }

    func lockEnclosingScrollView() {
        var current = superview
        while let view = current {
            if let scrollView = view as? UIScrollView {
                scrollView.bounces = false
                scrollView.alwaysBounceVertical = false
                return
            }
            current = view.superview
        }
    }
}
