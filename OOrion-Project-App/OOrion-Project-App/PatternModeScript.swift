//
//  PatternModel.swift
//  OOrion-Project-App
//
//  Created by Yassine Terrab on 03/03/2022.
//  Copyright © 2022 Shuichi Tsutsumi. All rights reserved.
//

import Foundation
import CoreML
import UIKit

func RunPatternModel (ImageBuffer : UIImage) -> String {
    let model = PatternModel()
    
//    let GrayImage = ImageBuffer.noir
    let RszdImage = resizeImage(image: ImageBuffer, newWidth: CGFloat(PatternImageSize))
    let RszdImageCVPB = RszdImage?.toCVPixelBuffer()
    
    
    let test = PatternModelInput(input_86: RszdImageCVPB!)
    guard let PatternModelOutput = try? model.prediction(input: test) else {
        print(CVPixelBufferGetWidth(RszdImageCVPB!))
        print(CVPixelBufferGetHeight(RszdImageCVPB!))
        fatalError ("Unexpected runtime error.")
    }
    
    let dict = PatternModelOutput.Identity
    
    var label = ""
    var maxKey = -1
    var maxConf = 0.0
    
    for key in dict.keys {
        if dict[key]! > maxConf && dict[key]! > ModelThres {
            maxConf = dict[key]!
            maxKey = Int(key)
     }
    }
    
    switch  maxKey {
    case 2  :
      label = "Rayé"
    case 1:
     label = "A pois"
    case 0:
     label = "A carreaux"
    case 3:
     label = "solid"
    default:
     label = " "
    }

    return label
}



extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }

        if let pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

            context?.translateBy(x: 0, y: self.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)

            UIGraphicsPushContext(context!)
            self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

            return pixelBuffer
        }

        return nil
    }
    
    var noir: UIImage? {
            let context = CIContext(options: nil)
            guard let currentFilter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
            currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
            if let output = currentFilter.outputImage,
                let cgImage = context.createCGImage(output, from: output.extent) {
                return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
            }
            return nil
        }
    
}



func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {

    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage
}




    
    
    
    


