import SwiftUI

class OverlayManager: ObservableObject {
    @Published var showPaywall: Bool = false
    var isOverlayActive: Bool { showPaywall }
    @Published var isOverlayVisible: Bool = false
    func show() {
        showPaywall = true
    }

    func hide() {
        showPaywall = false
    }
}

class OverlayLock: ObservableObject {
    @Published var isVisible = false
    var isOverlayActive: Bool { isVisible }

    func show() {
        withAnimation {
            isVisible = true
        }
    }

    func hide() {
        withAnimation {
            isVisible = false
        }
    }
}
