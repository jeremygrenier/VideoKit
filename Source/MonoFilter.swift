//
//  MonoFilter.swift
//  VideoKit
//
//  Created by Jeremy Grenier on 17/11/2016.
//  Copyright © 2016 Jeremy Grenier. All rights reserved.
//

import Foundation

public struct MonoFilter: VideoFilter
{
    public init() {}

    public func filter(on source: CIImage) -> CIImage
    {
        let params = [kCIInputImageKey: source]

        if let filter = CIFilter(name: "CIPhotoEffectMono", withInputParameters: params),
            let outputImage = filter.outputImage {
            return outputImage
        }

        return source
    }
}
