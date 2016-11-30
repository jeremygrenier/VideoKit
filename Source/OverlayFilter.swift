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
            let matrix = transform.concatenating(CGAffineTransform(translationX: size.width, y: 0))

            overlay = CIImage(cgImage: cgImage).applying(matrix)
        }
    }

    public func filter(on source: CIImage) -> CIImage
    {
        guard let overlay = overlay else { return source }

        let params = [kCIInputImageKey: overlay, kCIInputBackgroundImageKey: source]
        if let filter = CIFilter(name: "CISourceOverCompositing", withInputParameters: params),
            let outputImage = filter.outputImage {
            return outputImage
        }

        return source
    }
}
