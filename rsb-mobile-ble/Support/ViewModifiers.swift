//
//  ViewModifiers.swift
//  rsb-mobile-ble
//
//  Created by Astro on 6/28/24.
//

import SwiftUI

// from: https://stackoverflow.com/questions/56496359/swiftui-view-viewdidload

struct ViewDidLoadModifier: ViewModifier {

    @State private var didLoad = false
    private let action: (() -> Void)?

    init(perform action: (() -> Void)? = nil) {
        self.action = action
    }

    func body(content: Content) -> some View {
        content.onAppear {
            if !didLoad {
                didLoad = true
                action?()
            }
        }
    }
}

extension View {
    func onLoad(perform action: (() -> Void)? = nil) -> some View {
        modifier(ViewDidLoadModifier(perform: action))
    }
}
