//
//  PlatformViewModel+Ext.swift
//  PlatformUI
//
//  Created by Rui Huang on 8/3/23.
//

import Foundation
import UIKit
import SwiftUI

public extension PlatformViewModel {
    var safeAreaInsets: UIEdgeInsets? {
        keyWindow?.safeAreaInsets
    }

    var keyWindow: UIWindow? {
        UIApplication
            .shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .last
    }
}

public extension View {
    var safeAreaInsets: UIEdgeInsets? {
        keyWindow?.safeAreaInsets
    }

    var keyWindow: UIWindow? {
        UIApplication
            .shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .last
    }
}
