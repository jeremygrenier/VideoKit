//
//  ViewController.swift
//  VideoKitExample
//
//  Created by Jeremy Grenier on 17/11/2016.
//  Copyright © 2016 Jeremy Grenier. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Metal

import VideoKit

enum RenderingMode
{
    case layer
    case openGL
}

class ViewController: UIViewController
{
    let renderingMode = RenderingMode.openGL

    let library = PHPhotoLibrary.shared()
    var outputFileURL: URL?

    var writter: VideoKit.VideoWriter!
    var transform = CGAffineTransform.identity

    let imageView = OpenGLImageView()

    @IBOutlet weak var playButton: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!

    @IBAction func playPressed(for sender: UIBarButtonItem)
    {
        sender.isEnabled = false

        let path = Bundle.main.path(forResource: "sample_15", ofType: "mp4")

        let url = URL(fileURLWithPath: path!)
        let asset = AVURLAsset(url: url, options: nil)
        let watermark = UIImage(named: "watermark")!

        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        outputFileURL = URL(fileURLWithPath: documentDirectory).appendingPathComponent("mergeVideo.mp4")

        let videoTrack =  asset.tracks(withMediaType: AVMediaTypeVideo)[0]
        let size = videoTrack.naturalSize
        transform = videoTrack.preferredTransform

        let filter = OverlayFilter(image: watermark, size: size, transform: transform)
        let composition = CompositionRender(asset: asset, filters: [filter])

        transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(M_PI)))

        writter = VideoWriter(outputFileURL: outputFileURL!, render: composition)
        writter.delegate = self

        writter.startRender()
    }

    func openGLRendering(frame: CIImage)
    {
        DispatchQueue.main.async {
            self.imageView.image = frame
        }
    }

    func viewRendering(frame: CIImage)
    {
        if let frame = frame.createCGImage {
            DispatchQueue.main.async {
                self.view.layer.contents = frame
            }
        }
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        if renderingMode == .openGL {
            view.insertSubview(imageView, at: 0)
        }

        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()

        imageView.frame = view.bounds
    }

    @IBAction func export()
    {
        guard let outputURL = outputFileURL else { return }

        library.performChanges( {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
        }, completionHandler: { (completed, error) in
            var title = ""
            var message = ""
            if error != nil {
                title = "Error"
                message = "Failed to save video"
            } else {
                title = "Success"
                message = "Video saved"
            }
            
            print("\(title): \(message)")
        })
    }
}

extension ViewController: VideoWriterDelegate
{
    func render(frame: CIImage)
    {
        let newFrame = frame.applying(transform)

        if renderingMode == .openGL {
            openGLRendering(frame: newFrame)
        } else {
            viewRendering(frame: newFrame)
        }
    }

    func finishWriting(for url: URL?, error: Error?)
    {
        playButton.isEnabled = true
        print("finish writing")
    }
}
