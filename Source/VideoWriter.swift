//
//  VideoWriter.swift
//  VideoKit
//
//  Created by Jeremy Grenier on 17/11/2016.
//  Copyright © 2016 Jeremy Grenier. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

public protocol VideoWriterDelegate: class
{
    func render(frame: CIImage)

    func finishWriting(for url: URL?, error: Error?)
}

public final class VideoWriter
{
    public weak var delegate: VideoWriterDelegate?

    private let glContext: EAGLContext
    private  let ciContext: CIContext
    private  let writer: AVAssetWriter

    class func setupWriter(outputFileURL: URL) -> AVAssetWriter
    {
        let fileManager = FileManager.default

        let outputFileExists = fileManager.fileExists(atPath: outputFileURL.path)
        if outputFileExists {
            do {
                try fileManager.removeItem(at: outputFileURL)
            } catch _ {}
        }

        let writer = try! AVAssetWriter(outputURL: outputFileURL, fileType: AVFileTypeMPEG4)

        return writer
    }

    public lazy var videoOutputSettings: [String: Any] = {
        return [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: Int(self.render.size.width),
            AVVideoHeightKey: Int(self.render.size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 2000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
            ]
        ]
    }()

    public lazy var audioOutputSettings: [String: Any] = {
        return [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 64000
        ]
    }()

    public lazy var sourcePixelBufferAttributes: [String: Any] = {
        return [
            String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA,
            String(kCVPixelBufferWidthKey): Int(self.render.size.width),
            String(kCVPixelBufferHeightKey): Int(self.render.size.height)
        ]
    }()

    var videoInput: AVAssetWriterInput!
    var audioInput: AVAssetWriterInput!

    var isVideoCompleted = false
    var isAudioCompleted = false

    var writerInputAdapater: AVAssetWriterInputPixelBufferAdaptor!

    let render: CompositionRender

    private var lastTime = kCMTimeZero
    private var inputQueue = DispatchQueue(label: "me.jgrenier.videokit.input_queue")

    public init(outputFileURL: URL, render: CompositionRender)
    {
        self.render = render

        glContext = EAGLContext(api: .openGLES2)
        ciContext = CIContext(eaglContext: glContext)

        writer = VideoWriter.setupWriter(outputFileURL: outputFileURL)

        // Audio
        audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioOutputSettings)
        audioInput.expectsMediaDataInRealTime = false
        writer.add(audioInput)

        // Video
        videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoOutputSettings)
        videoInput.transform = render.transform
        videoInput.expectsMediaDataInRealTime = false
        writer.add(videoInput)

        writerInputAdapater = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)

        writer.startWriting()

        writer.startSession(atSourceTime: kCMTimeZero)
    }

    private func finishWriting()
    {
        videoInput.markAsFinished()
        writer.endSession(atSourceTime: lastTime)
        writer.finishWriting {
            self.delegate?.finishWriting(for: self.writer.outputURL, error: nil)
        }
    }

    private func write(image: CIImage, withPresentationTime time: CMTime)
    {
        lastTime = time

        guard let pixelBufferPool = writerInputAdapater.pixelBufferPool else {
            fatalError("Failed to allocate the PixelBufferPool")
        }

        var pixelBufferOut: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)

        guard let pixelBuffer = pixelBufferOut else {
            fatalError("Failed to create the PixelBuffer")
        }

        ciContext.render(image, to: pixelBuffer)
        writerInputAdapater.append(pixelBuffer, withPresentationTime: time)

        delegate?.render(frame: image)
    }

    public func startRender()
    {
        renderVideo()
        renderAudio()
    }

    private func renderVideo()
    {
        videoInput.requestMediaDataWhenReady(on: inputQueue) { [unowned self] () -> Void in
            while self.videoInput.isReadyForMoreMediaData {
                autoreleasepool {
                    if let (image, time) = self.render.nextVideo() {
                        self.write(image: image, withPresentationTime: time)
                    } else {
                        self.videoInput.markAsFinished()
                        self.isVideoCompleted = true
                        if self.isAudioCompleted {
                            self.finishWriting()
                        }
                        return
                    }
                }
            }
        }
    }

    private func renderAudio()
    {
        audioInput.requestMediaDataWhenReady(on: inputQueue) { [unowned self] () -> Void in
            while self.audioInput.isReadyForMoreMediaData {
                if let nextBuffer = self.render.nextAudio() {
                    self.audioInput.append(nextBuffer)
                } else {
                    self.audioInput.markAsFinished()
                    self.isAudioCompleted = true
                    if self.isVideoCompleted {
                        self.finishWriting()
                    }
                    return
                }
            }
        }

        if isVideoCompleted {
            delegate?.finishWriting(for: writer.outputURL, error: nil)
        }
    }

}

public final class CompositionRender
{
    public let acceleration: Float = 1.0

    let filters: [VideoFilter]
    let reader: VideoSeqReader

    var size = CGSize.zero
    var transform = CGAffineTransform.identity

    var frameCount: Int64 = 0

    public init(asset: AVAsset, filters: [VideoFilter])
    {
        self.filters = filters
        reader = VideoSeqReader(asset: asset)

        let videoTrack =  asset.tracks(withMediaType: AVMediaTypeVideo)[0]

        transform = videoTrack.preferredTransform
        size = videoTrack.naturalSize
    }

    func nextAudio() -> CMSampleBuffer?
    {
        return reader.audioOutput.copyNextSampleBuffer()
    }

    public func nextVideo() -> (CIImage, CMTime)?
    {
        if let frame = reader.next() {
            let frameRate = Int32(reader.nominalFrameRate * acceleration)
            let presentationTime = CMTimeMake(frameCount, frameRate)
            let image = frame.filterWith(filters: filters)
            
            frameCount += 1

            return (image, presentationTime)
        }
        return nil
    }
}
