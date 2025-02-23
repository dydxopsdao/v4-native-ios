//
//  dydxAdjustMarginCtaButtonView.swift
//  dydxUI
//
//  Created by Rui Huang on 09/05/2024.
//  Copyright © 2024 dYdX Trading Inc. All rights reserved.
//

import SwiftUI
import PlatformUI
import Utilities

public class dydxAdjustMarginCtaButtonViewModel: PlatformViewModel {
    public enum State {
        case enabled(String)
        case disabled(String? = nil)
        case thinking
    }

    @Published public var ctaAction: (() -> Void)?
    @Published public var ctaButtonState: State = .disabled()

    public init() { }

    public static var previewValue: dydxAdjustMarginCtaButtonViewModel {
        let vm = dydxAdjustMarginCtaButtonViewModel()
        vm.ctaButtonState = .enabled("OK")
        return vm
    }

    public override func createView(parentStyle: ThemeStyle = ThemeStyle.defaultStyle, styleKey: String? = nil) -> PlatformView {
        PlatformView(viewModel: self, parentStyle: parentStyle, styleKey: styleKey) { [weak self] style in
            guard let self = self else { return AnyView(PlatformView.nilView) }

            return AnyView(
                self.createCtaButton(parentStyle: style)
            )
        }
    }

    private func createCtaButton(parentStyle style: ThemeStyle) -> some View {
        let buttonTitle: String
        let state: PlatformButtonState
        switch ctaButtonState {
        case .enabled(let title):
            buttonTitle = title
            state = .primary
        case .disabled(let title):
            buttonTitle = title ?? DataLocalizer.localize(path: "APP.TRADE.ENTER_AMOUNT")
            state = .disabled
        case .thinking:
            buttonTitle = DataLocalizer.localize(path: "APP.V4.CALCULATING")
            state = .disabled
        }

        let buttonContent =
            Text(buttonTitle)
                .wrappedViewModel

        return PlatformButtonViewModel(content: buttonContent,
                                       state: state) { [weak self] in
            PlatformView.hideKeyboard()
            self?.ctaAction?()
        }
           .createView(parentStyle: style)
           .animation(.easeInOut(duration: 0.1))
    }
}

#if DEBUG
struct dydxAdjustMarginCtaButtonView_Previews_Dark: PreviewProvider {
    @StateObject static var themeSettings = ThemeSettings.shared

    static var previews: some View {
        ThemeSettings.applyDarkTheme()
        ThemeSettings.applyStyles()
        return dydxAdjustMarginCtaButtonViewModel.previewValue
            .createView()
            .themeColor(background: .layer0)
            .environmentObject(themeSettings)
            // .edgesIgnoringSafeArea(.bottom)
            .previewLayout(.sizeThatFits)
    }
}

struct dydxAdjustMarginCtaButtonView_Previews_Light: PreviewProvider {
    @StateObject static var themeSettings = ThemeSettings.shared

    static var previews: some View {
        ThemeSettings.applyLightTheme()
        ThemeSettings.applyStyles()
        return dydxAdjustMarginCtaButtonViewModel.previewValue
            .createView()
            .themeColor(background: .layer0)
            .environmentObject(themeSettings)
        // .edgesIgnoringSafeArea(.bottom)
            .previewLayout(.sizeThatFits)
    }
}
#endif
