//
//  VideoFilter.swift
//  VideoKit
//
//  Created by Jeremy Grenier on 17/11/2016.
//  Copyright © 2016 Jeremy Grenier. All rights reserved.
//

import Foundation

public protocol VideoFilter
{
    func filter(on source: CIImage) -> CIImage
}

extension VideoFilter
{
    func filter(on source: CIImage) -> CIImage
    {
        return source
    }
}
