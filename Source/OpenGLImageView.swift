//
//  OpenGLImageView.swift
//  Pods
//
//  Created by Jeremy Grenier on 17/11/2016.
//
//

import Foundation
import GLKit

public class OpenGLImageView: GLKView
{
    public var image: CIImage? {
        didSet {
            setNeedsDisplay()
        }
    }

    let eaglContext = EAGLContext(api: .openGLES3)

    lazy var ciContext: CIContext = { [unowned self] in
            return CIContext(eaglContext: self.eaglContext!, options: [kCIContextWorkingColorSpace: NSNull()])
        }()

    override init(frame: CGRect)
    {
        super.init(frame: frame, context: eaglContext!)

        context = eaglContext!
        delegate = self
    }

    override init(frame: CGRect, context: EAGLContext)
    {
        fatalError("init(frame:, context:) has not been implemented")
    }

    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}

extension OpenGLImageView: GLKViewDelegate
{
    public func glkView(_ view: GLKView, drawIn rect: CGRect)
    {
        guard let image = image else { return }

        let size = CGSize(width: drawableWidth, height: drawableHeight)
        let rect = CGRect(origin: .zero, size: size)
        let targetRect = image.extent.aspectFitInRect(target: rect)

        let ciBackgroundColor = CIColor(color: backgroundColor ?? .white)
        ciContext.draw(CIImage(color: ciBackgroundColor), in: rect, from: rect)

        ciContext.draw(image, in: targetRect, from: image.extent)
    }
}

extension CGRect
{
    func aspectFitInRect(target: CGRect) -> CGRect
    {
        let scale: CGFloat = {
                let scale = target.width / self.width
                return self.height * scale <= target.height ? scale : target.height / self.height
        }()

        let width = self.width * scale
        let height = self.height * scale
        let x = target.midX - width / 2
        let y = target.midY - height / 2

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
