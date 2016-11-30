//
//  VideoSeqReader.swift
//  VideoKit
//
//  Created by Jeremy Grenier on 17/11/2016.
//  Copyright © 2016 Jeremy Grenier. All rights reserved.
//

import Foundation
import AVFoundation

final class VideoSeqReader
{
    let videoOutput: AVAssetReaderTrackOutput
    let audioOutput: AVAssetReaderAudioMixOutput

    let reader: AVAssetReader

    let nominalFrameRate: Float

    init(asset: AVAsset)
    {
        reader = try! AVAssetReader(asset: asset)

        let videoTrack = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
        let outputSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        videoOutput.alwaysCopiesSampleData = false

        if reader.canAdd(videoOutput) {
            reader.add(videoOutput)
        }

        let audioTracks = asset.tracks(withMediaType: AVMediaTypeAudio)
        audioOutput = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: nil)
        audioOutput.alwaysCopiesSampleData = false

        if reader.canAdd(audioOutput) {
            reader.add(audioOutput)
        }

        nominalFrameRate = videoTrack.nominalFrameRate

        assert(reader.status != .failed, "reader started failed error \(reader.error)")

        reader.startReading()
    }

    func next() -> CIImage? {

        if let sb = videoOutput.copyNextSampleBuffer() {
            if let pxbuffer = CMSampleBufferGetImageBuffer(sb) {
                return CIImage(cvPixelBuffer: pxbuffer)
            }
        }
        
        return nil
    }
}
