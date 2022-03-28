//
//  PatternDetection.swift
//  OOrion-Project-App
//
//  Created by Yassine Terrab on 03/03/2022.
//  Copyright © 2022 Shuichi Tsutsumi. All rights reserved.
//

import Foundation
import CoreML
import UIKit

extension UIImage {
    
    /// Convertsa UIImage to a CVPixelBuffer
    ///
    /// - Parameter value:
    /// - Returns:CVPixelBuffer created from the UIImage
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
}

var listPattern: [String] = []

/// Runs the model named PatternModel, found at the root of the app folder, and adds to ListPatterns the pattern name if the confidence is above the threshold
///
/// - Parameter value: ImageBuffer : the UIImage on which the model will be run
/// - Returns:
func RunPatternModel (ImageBuffer : UIImage) {
    let model = PatternModel()
    
    let rszdImage = resizeImage(image: ImageBuffer, newWidth: CGFloat(PatternImageSize))
    let rszdImageCVPB = rszdImage?.toCVPixelBuffer()
    
    
    let _input = PatternModelInput(input_6: rszdImageCVPB!)
    guard let PatternModelOutput = try? model.prediction(input: _input) else {
        fatalError ("Unexpected runtime error.")
    }
    
    let dict = PatternModelOutput.Identity
    
    var label = ""
    var maxKey = -1
    var maxConf = 0.0
    
    for key in dict.keys {
        if dict[key]! > maxConf && dict[key]! > ModelThres[Int(key)] {
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
    default:
        label = " "
    }

    listPattern.append(label)
}

/// Returns the most frequent pattern in ListPattern
///
/// - Parameter value:
/// - Returns:a String containing the pattern name
func GetPattern() -> String {
    var scores = [0, 0, 0, 0, 0]
    let patternNames = ["A carreaux", "A pois", "Rayé", "nothing"]
    for patternName in listPattern {
        switch patternName {
        case "A carreaux":
            scores[0] = scores[0] + 1
        case "A pois":
            scores[1] = scores[1] + 1
        case "Rayé":
            scores[2] = scores[2] + 1
        default:
            scores[3] = scores[3] + 1
        }
    }
    let highScore = scores.max()
    listPattern = []
    if scores.firstIndex(of:highScore!) == scores.lastIndex(of:highScore!) {
        let winningPatternIndex = scores.firstIndex(of:highScore!)
        let winningPattern = patternNames[winningPatternIndex!]
        return winningPattern
    }
    else {
        return "nothing"
    }
}


/// Resize UIImage to a square of given width
///
/// - Parameter value: image : UIImage to resize
///                    newWidth : CGFloat corresponding to the new dimension of the image
/// - Returns:image resized to given width
func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage
}


    
    


