//
//  CIImageExtensions.swift
//  VideoKit
//
//  Created by Jeremy Grenier on 17/11/2016.
//  Copyright © 2016 Jeremy Grenier. All rights reserved.
//

import Foundation

public extension CIImage
{
    public var createCGImage: CGImage! {
        get {
            let context = CIContext(options: nil)
            return context.createCGImage(self, from: self.extent)
        }
    }


    func filterWith(filters: [VideoFilter]) -> CIImage
    {
        var merge = self

        for filter in filters {
            merge = filter.filter(on: merge)
        }

        return merge
    }
}
