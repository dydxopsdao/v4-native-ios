//
//  RectPreviewOverlay.swift
//  UIToolkits
//
//  Created by Qiang Huang on 7/11/20.
//  Copyright © 2020 dYdX. All rights reserved.
//

import Foundation

open class RectPreviewOverlay: PreviewOverlay {
    open var aspectRatio: CGFloat = 1.0
    open var margin: CGFloat = 0.1

    open override func path(rect: CGRect) -> UIBezierPath? {
        var width = rect.width * (1.0 - margin * 2)
        var height = rect.height * (1.0 - margin * 2)
        // aspectRatio = width / height
        if width / aspectRatio > height {
            width = height * aspectRatio
        } else {
            height = width / aspectRatio
        }
        let rectRect = CGRect(x: (rect.width - width) / 2.0, y: (rect.height - height) / 2.0, width: width, height: height)
        let path = UIBezierPath(rect: rect)
        path.append(UIBezierPath(rect: rectRect))
        return path
    }
}
