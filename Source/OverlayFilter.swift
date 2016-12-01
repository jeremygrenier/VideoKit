//
//  OverlayFilter.swift
//  VideoKit
//
//  Created by Jeremy Grenier on 17/11/2016.
//  Copyright © 2016 Jeremy Grenier. All rights reserved.
//

import Foundation
import CoreImage

public struct OverlayFilter: VideoFilter
{
    var overlay: CIImage?

    public init(image: UIImage, size: CGSize, transform: CGAffineTransform = .identity)
    {
        if let cgImage = image.cgImage {

            var matrix = transform

            if transform.b != 0 && transform.b == transform.c {
                matrix = transform.concatenating(CGAffineTransform(rotationAngle: .pi))
            }

            let overlay = CIImage(cgImage: cgImage).applying(matrix)
            let rect = overlay.extent

            self.overlay = overlay.applying(CGAffineTransform(translationX: -rect.origin.x, y: -rect.origin.y))
        }
    }

    public func filter(on source: CIImage) -> CIImage
    {
        guard let overlay = overlay else { return source }

        let outputImage = overlay.compositingOverImage(source)
        return outputImage
    }
}
